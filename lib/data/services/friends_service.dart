import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/friend.dart';
import 'base_firestore_service.dart';

class FriendsService extends BaseFirestoreService {
  FriendsService({super.firestore, super.auth});

  CollectionReference get _friendsCollection => collection('friendships');

  Future<Friend> sendFriendRequest(String otherUserId) async {
    requireAuth();
    final currentId = currentUserId!;
    if (otherUserId == currentId) {
      throw Exception('Không thể gửi lời mời cho chính mình');
    }
    try {
      final existing = await _findFriendship(currentId, otherUserId);
      if (existing != null) {
        throw Exception('Friend request already exists');
      }

      final now = DateTime.now();
      final friend = Friend(
        id: '',
        userId1: currentId,
        userId2: otherUserId,
        requestedBy: currentId,
        status: FriendStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _friendsCollection.add(friend.toFirestore());
      final docSnapshot = await docRef.get();
      return Friend.fromFirestore(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
    } catch (e) {
      throw Exception('Error sending friend request: $e');
    }
  }

  Future<void> acceptFriendRequest(String otherUserId) async {
    requireAuth();
    final currentId = currentUserId!;
    try {
      final friendship = await _findFriendship(currentId, otherUserId);
      if (friendship == null) {
        throw Exception('Friend request not found');
      }
      if (friendship.status != FriendStatus.pending) {
        throw Exception('Friend request already processed');
      }
      if (friendship.requestedBy == currentId) {
        throw Exception('Cannot accept your own request');
      }

      await _friendsCollection.doc(friendship.id).update({
        'status': FriendStatus.accepted.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error accepting friend request: $e');
    }
  }

  Future<void> blockFriend(String otherUserId) async {
    requireAuth();
    final currentId = currentUserId!;
    try {
      final friendship = await _findFriendship(currentId, otherUserId);
      if (friendship == null) {
        throw Exception('Friendship not found');
      }

      await _friendsCollection.doc(friendship.id).update({
        'status': FriendStatus.blocked.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error blocking friend: $e');
    }
  }

  Future<void> removeFriend(String otherUserId) async {
    requireAuth();
    final currentId = currentUserId!;
    try {
      final friendship = await _findFriendship(currentId, otherUserId);
      if (friendship == null) {
        throw Exception('Friendship not found');
      }

      await _friendsCollection.doc(friendship.id).delete();
    } catch (e) {
      throw Exception('Error removing friend: $e');
    }
  }

  Future<List<Friend>> getFriends() async {
    requireAuth();
    final currentId = currentUserId!;
    try {
      final query1 = await _friendsCollection
          .where('userId1', isEqualTo: currentId)
          .where('status', isEqualTo: FriendStatus.accepted.name)
          .get();

      final query2 = await _friendsCollection
          .where('userId2', isEqualTo: currentId)
          .where('status', isEqualTo: FriendStatus.accepted.name)
          .get();

      final all = [...query1.docs, ...query2.docs];
      return all
          .map((doc) => Friend.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Error getting friends: $e');
    }
  }

  Future<List<Friend>> getPendingRequests() async {
    requireAuth();
    final currentId = currentUserId!;
    try {
      final query1 = await _friendsCollection
          .where('userId1', isEqualTo: currentId)
          .where('status', isEqualTo: FriendStatus.pending.name)
          .get();

      final query2 = await _friendsCollection
          .where('userId2', isEqualTo: currentId)
          .where('status', isEqualTo: FriendStatus.pending.name)
          .get();

      final all = [...query1.docs, ...query2.docs];
      final pending = all
          .map((doc) => Friend.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .where((friendship) => friendship.requestedBy != currentId)
          .toList();

      return pending;
    } catch (e) {
      throw Exception('Error getting pending requests: $e');
    }
  }

  Stream<List<Friend>> streamIncomingPendingRequests() {
    final currentId = currentUserId;
    if (currentId == null) return const Stream<List<Friend>>.empty();

    final controller = StreamController<List<Friend>>();
    List<Friend> pendingUser1 = [];
    List<Friend> pendingUser2 = [];

    void emitCombined() {
      final combined = <String, Friend>{
        for (final item in [...pendingUser1, ...pendingUser2]) item.id: item,
      };
      final incoming = combined.values
          .where((friendship) => friendship.requestedBy != currentId)
          .toList();
      controller.add(incoming);
    }

    StreamSubscription<QuerySnapshot>? sub1;
    StreamSubscription<QuerySnapshot>? sub2;

    sub1 = _friendsCollection
        .where('userId1', isEqualTo: currentId)
        .where('status', isEqualTo: FriendStatus.pending.name)
        .snapshots()
        .listen(
          (snap) {
            pendingUser1 = snap.docs
                .map((doc) => Friend.fromFirestore(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ))
                .toList();
            emitCombined();
          },
          onError: controller.addError,
        );

    sub2 = _friendsCollection
        .where('userId2', isEqualTo: currentId)
        .where('status', isEqualTo: FriendStatus.pending.name)
        .snapshots()
        .listen(
          (snap) {
            pendingUser2 = snap.docs
                .map((doc) => Friend.fromFirestore(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ))
                .toList();
            emitCombined();
          },
          onError: controller.addError,
        );

    controller.onCancel = () {
      sub1?.cancel();
      sub2?.cancel();
    };

    return controller.stream;
  }

  Stream<int> streamIncomingPendingCount() {
    return streamIncomingPendingRequests().map((items) => items.length);
  }

  int countUnseenInvites(List<Friend> invites, DateTime? lastSeen) {
    if (invites.isEmpty) return 0;
    if (lastSeen == null) return invites.length;
    return invites.where((invite) {
      final createdAt = invite.createdAt;
      if (createdAt == null) return true;
      return createdAt.isAfter(lastSeen);
    }).length;
  }

  Future<List<Friend>> getFriendships() async {
    requireAuth();
    final currentId = currentUserId!;
    try {
      final query1 = await _friendsCollection.where('userId1', isEqualTo: currentId).get();
      final query2 = await _friendsCollection.where('userId2', isEqualTo: currentId).get();
      final all = [...query1.docs, ...query2.docs];
      return all
          .map((doc) => Friend.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Error getting friendships: $e');
    }
  }

  String getOtherUserId(Friend friendship, String currentId) {
    return friendship.userId1 == currentId ? friendship.userId2 : friendship.userId1;
  }

  Future<Friend?> _findFriendship(String userIdA, String userIdB) async {
    try {
      final query1 = await _friendsCollection
          .where('userId1', isEqualTo: userIdA)
          .where('userId2', isEqualTo: userIdB)
          .limit(1)
          .get();

      if (query1.docs.isNotEmpty) {
        final doc = query1.docs.first;
        return Friend.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }

      final query2 = await _friendsCollection
          .where('userId1', isEqualTo: userIdB)
          .where('userId2', isEqualTo: userIdA)
          .limit(1)
          .get();

      if (query2.docs.isEmpty) return null;
      final doc = query2.docs.first;
      return Friend.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (_) {
      return null;
    }
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/friend.dart';
import 'base_firestore_service.dart';

class FriendsService extends BaseFirestoreService {
  FriendsService({super.firestore, super.auth});

  CollectionReference get _friendsCollection => collection('friends');

  /// Gửi friend request
  Future<Friend> sendFriendRequest(String friendId) async {
    requireAuth();
    try {
      // Kiểm tra đã có request chưa
      final existing = await _findFriendship(currentUserId!, friendId);
      if (existing != null) {
        throw Exception('Friend request already exists');
      }

      final now = DateTime.now();
      final friend = Friend(
        id: '',
        userId: currentUserId!,
        friendId: friendId,
        status: FriendStatus.pending,
        requestedAt: now,
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

  /// Chấp nhận friend request
  Future<void> acceptFriendRequest(String friendId) async {
    requireAuth();
    try {
      final friendship = await _findFriendship(friendId, currentUserId!);
      if (friendship == null) {
        throw Exception('Friend request not found');
      }
      if (friendship.status != FriendStatus.pending) {
        throw Exception('Friend request already processed');
      }

      await _friendsCollection.doc(friendship.id).update({
        'status': FriendStatus.accepted.name,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error accepting friend request: $e');
    }
  }

  /// Từ chối/Block friend
  Future<void> blockFriend(String friendId) async {
    requireAuth();
    try {
      final friendship = await _findFriendship(currentUserId!, friendId) ??
          await _findFriendship(friendId, currentUserId!);
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

  /// Xóa friend/unfriend
  Future<void> removeFriend(String friendId) async {
    requireAuth();
    try {
      final friendship = await _findFriendship(currentUserId!, friendId) ??
          await _findFriendship(friendId, currentUserId!);
      if (friendship == null) {
        throw Exception('Friendship not found');
      }

      await _friendsCollection.doc(friendship.id).delete();
    } catch (e) {
      throw Exception('Error removing friend: $e');
    }
  }

  /// Lấy danh sách bạn bè
  Future<List<Friend>> getFriends() async {
    requireAuth();
    try {
      // Lấy cả 2 chiều: user là userId hoặc friendId
      final query1 = await _friendsCollection
          .where('userId', isEqualTo: currentUserId)
          .where('status', isEqualTo: FriendStatus.accepted.name)
          .get();

      final query2 = await _friendsCollection
          .where('friendId', isEqualTo: currentUserId)
          .where('status', isEqualTo: FriendStatus.accepted.name)
          .get();

      final all = [
        ...query1.docs,
        ...query2.docs,
      ];

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

  /// Lấy danh sách friend requests đang chờ
  Future<List<Friend>> getPendingRequests() async {
    requireAuth();
    try {
      final querySnapshot = await _friendsCollection
          .where('friendId', isEqualTo: currentUserId)
          .where('status', isEqualTo: FriendStatus.pending.name)
          .orderBy('requestedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Friend.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Error getting pending requests: $e');
    }
  }

  /// Helper: Tìm friendship giữa 2 users
  Future<Friend?> _findFriendship(String userId, String friendId) async {
    try {
      final querySnapshot = await _friendsCollection
          .where('userId', isEqualTo: userId)
          .where('friendId', isEqualTo: friendId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return Friend.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      return null;
    }
  }
}


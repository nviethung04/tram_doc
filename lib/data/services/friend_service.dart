import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_user.dart';
import '../../models/friendship.dart';

class FriendService {
  final _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> searchUsers(String keyword) async {
    keyword = keyword.trim().toLowerCase();
    if (keyword.isEmpty) return [];

    final snap = await _db
        .collection('users')
        .where('keywords', arrayContains: keyword)
        .limit(20)
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      return {
        'id': d.id,
        'displayName': data['displayName'],
        'bio': data['bio'],
        'photoUrl': data['photoUrl'],
      };
    }).toList();
  }

  /* =========================
     CREATE FRIEND REQUEST
  ========================== */
  Future<void> createFriendRequest(
      String fromUid, String toUid) async {
    if (fromUid == toUid) return;

    final exist = await _db
        .collection('friendships')
        .where('userA', whereIn: [fromUid, toUid])
        .where('userB', whereIn: [fromUid, toUid])
        .get();

    if (exist.docs.isNotEmpty) return;

    await _db.collection('friendships').add({
      'userA': fromUid,
      'userB': toUid,
      'requestedBy': fromUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /* =========================
     FRIEND STATUS MAP
  ========================== */
  Future<Map<String, String>> getFriendshipStatusMap(
      String uid) async {
    final result = <String, String>{};

    final snapA = await _db
        .collection('friendships')
        .where('userA', isEqualTo: uid)
        .get();

    final snapB = await _db
        .collection('friendships')
        .where('userB', isEqualTo: uid)
        .get();

    for (final d in [...snapA.docs, ...snapB.docs]) {
      final f = Friendship.fromDoc(d);
      final other = f.otherUser(uid);

      if (f.status == 'accepted') {
        result[other] = 'accepted';
      } else if (f.status == 'pending') {
        result[other] =
            f.requestedBy == uid ? 'pending_sent' : 'pending_received';
      }
    }

    return result;
  }

  /* =========================
     GET FRIEND LIST
  ========================== */
  Future<List<AppUser>> getFriends(String uid) async {
    final snapA = await _db
        .collection('friendships')
        .where('userA', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .get();

    final snapB = await _db
        .collection('friendships')
        .where('userB', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .get();

    final ids = <String>{};

    for (final d in snapA.docs) {
      ids.add(d['userB']);
    }
    for (final d in snapB.docs) {
      ids.add(d['userA']);
    }

    if (ids.isEmpty) return [];

    final users = await _db
        .collection('users')
        .where(FieldPath.documentId, whereIn: ids.toList())
        .get();

    return users.docs
        .map((d) => AppUser.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> deleteFriendship(String id) async {}

  Future<void> updateFriendshipStatus(String id, String s) async {}

  Future<Map<String, dynamic>?>? getUserProfile(String requesterId) async {}

  Stream<List<Friendship>>? getRealFriendships(String uid) {}

  Future<dynamic> getFriendshipId(String userId, String uid) async {}
}

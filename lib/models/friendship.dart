import 'package:cloud_firestore/cloud_firestore.dart';

class Friendship {
  final String id;
  final String userA;
  final String userB;
  final String requestedBy;
  final String status; // pending | accepted
  final DateTime createdAt;

  Friendship({
    required this.id,
    required this.userA,
    required this.userB,
    required this.requestedBy,
    required this.status,
    required this.createdAt,
  });

  factory Friendship.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friendship(
      id: doc.id,
      userA: data['userA'],
      userB: data['userB'],
      requestedBy: data['requestedBy'],
      status: data['status'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  bool involves(String uid) => userA == uid || userB == uid;

  String otherUser(String uid) => userA == uid ? userB : userA;
}

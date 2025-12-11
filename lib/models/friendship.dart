import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendshipStatus { pending, accepted, blocked }

class Friendship {
  final String id;
  final String userId1;
  final String userId2;
  final FriendshipStatus status;
  final String requestedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Friendship({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.status,
    required this.requestedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId1': userId1,
      'userId2': userId2,
      'status': status.name,
      'requestedBy': requestedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Friendship.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friendship(
      id: doc.id,
      userId1: data['userId1'] ?? '',
      userId2: data['userId2'] ?? '',
      status: FriendshipStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FriendshipStatus.pending,
      ),
      requestedBy: data['requestedBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Friendship copyWith({
    String? id,
    String? userId1,
    String? userId2,
    FriendshipStatus? status,
    String? requestedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Friendship(
      id: id ?? this.id,
      userId1: userId1 ?? this.userId1,
      userId2: userId2 ?? this.userId2,
      status: status ?? this.status,
      requestedBy: requestedBy ?? this.requestedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String getOtherUserId(String currentUserId) {
    return currentUserId == userId1 ? userId2 : userId1;
  }
}


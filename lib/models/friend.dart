import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendStatus { pending, accepted, blocked }

class Friend {
  final String id;
  final String userId1;
  final String userId2;
  final String requestedBy;
  final FriendStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Friend({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.requestedBy,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId1': userId1,
      'userId2': userId2,
      'requestedBy': requestedBy,
      'status': status.name,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  factory Friend.fromFirestore(Map<String, dynamic> data, String id) {
    final rawStatus = data['status'];
    FriendStatus status;
    if (rawStatus is int && rawStatus >= 0 && rawStatus < FriendStatus.values.length) {
      status = FriendStatus.values[rawStatus];
    } else if (rawStatus is String) {
      status = FriendStatus.values.firstWhere(
        (s) => s.name == rawStatus,
        orElse: () => FriendStatus.pending,
      );
    } else {
      status = FriendStatus.pending;
    }

    return Friend(
      id: id,
      userId1: (data['userId1'] ?? '') as String,
      userId2: (data['userId2'] ?? '') as String,
      requestedBy: (data['requestedBy'] ?? '') as String,
      status: status,
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  static DateTime? _timestampToDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

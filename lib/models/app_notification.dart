import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String recipientId;
  final String actorId;
  final String? actorName;
  final String type;
  final String? bookId;
  final String? bookTitle;
  final String? activityId;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.actorId,
    this.actorName,
    required this.type,
    this.bookId,
    this.bookTitle,
    this.activityId,
    this.createdAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppNotification.fromMap(data, doc.id);
  }

  factory AppNotification.fromMap(Map<String, dynamic> data, String id) {
    return AppNotification(
      id: id,
      recipientId: (data['recipientId'] ?? '') as String,
      actorId: (data['actorId'] ?? '') as String,
      actorName: data['actorName'] as String?,
      type: (data['type'] ?? '') as String,
      bookId: data['bookId'] as String?,
      bookTitle: data['bookTitle'] as String?,
      activityId: data['activityId'] as String?,
      createdAt: _timestampToDateTime(data['createdAt']),
    );
  }

  static DateTime? _timestampToDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

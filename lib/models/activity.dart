import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  bookFinished,
  bookAdded,
  noteCreated,
  keyIdeaAdded,
  ratingUpdated,
}

enum ActivityVisibility { friends, public, private }

class Activity {
  final String id;
  final String userId;
  final ActivityType type;
  final String? bookId;
  final String? userBookId;
  final String? noteId;
  final int? rating;
  final String message;
  final ActivityVisibility visibility;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.userId,
    required this.type,
    this.bookId,
    this.userBookId,
    this.noteId,
    this.rating,
    required this.message,
    this.visibility = ActivityVisibility.public,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'bookId': bookId,
      'userBookId': userBookId,
      'noteId': noteId,
      'rating': rating,
      'message': message,
      'visibility': visibility.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Activity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: ActivityType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ActivityType.bookAdded,
      ),
      bookId: data['bookId'],
      userBookId: data['userBookId'],
      noteId: data['noteId'],
      rating: data['rating'],
      message: data['message'] ?? '',
      visibility: ActivityVisibility.values.firstWhere(
        (e) => e.name == data['visibility'],
        orElse: () => ActivityVisibility.public,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Activity copyWith({
    String? id,
    String? userId,
    ActivityType? type,
    String? bookId,
    String? userBookId,
    String? noteId,
    int? rating,
    String? message,
    ActivityVisibility? visibility,
    DateTime? createdAt,
  }) {
    return Activity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      bookId: bookId ?? this.bookId,
      userBookId: userBookId ?? this.userBookId,
      noteId: noteId ?? this.noteId,
      rating: rating ?? this.rating,
      message: message ?? this.message,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


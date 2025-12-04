import 'package:cloud_firestore/cloud_firestore.dart';

enum ReviewQuality {
  again, // Không nhớ
  hard, // Khó
  good, // Tốt
  easy, // Dễ
}

class Flashcard {
  final String id;
  final String noteId;
  final String bookId;
  final String userId;
  final String front; // Câu hỏi hoặc gợi ý
  final String back; // Câu trả lời
  final DateTime nextReviewDate;
  final int reviewCount;
  final double easeFactor; // Hệ số dễ dàng (Anki algorithm)
  final int interval; // Số ngày đến lần ôn tập tiếp theo
  final DateTime createdAt;
  final DateTime updatedAt;

  Flashcard({
    required this.id,
    required this.noteId,
    required this.bookId,
    required this.userId,
    required this.front,
    required this.back,
    required this.nextReviewDate,
    this.reviewCount = 0,
    this.easeFactor = 2.5, // Default ease factor
    this.interval = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'noteId': noteId,
      'bookId': bookId,
      'userId': userId,
      'front': front,
      'back': back,
      'nextReviewDate': Timestamp.fromDate(nextReviewDate),
      'reviewCount': reviewCount,
      'easeFactor': easeFactor,
      'interval': interval,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory Flashcard.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Flashcard(
      id: data['id'] ?? doc.id,
      noteId: data['noteId'] ?? '',
      bookId: data['bookId'] ?? '',
      userId: data['userId'] ?? '',
      front: data['front'] ?? '',
      back: data['back'] ?? '',
      nextReviewDate: (data['nextReviewDate'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      reviewCount: data['reviewCount'] ?? 0,
      easeFactor: (data['easeFactor'] as num?)?.toDouble() ?? 2.5,
      interval: data['interval'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create copy with updated fields
  Flashcard copyWith({
    String? id,
    String? noteId,
    String? bookId,
    String? userId,
    String? front,
    String? back,
    DateTime? nextReviewDate,
    int? reviewCount,
    double? easeFactor,
    int? interval,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      bookId: bookId ?? this.bookId,
      userId: userId ?? this.userId,
      front: front ?? this.front,
      back: back ?? this.back,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      reviewCount: reviewCount ?? this.reviewCount,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if card is due for review
  bool get isDue {
    return DateTime.now().isAfter(nextReviewDate) ||
        DateTime.now().isAtSameMomentAs(nextReviewDate);
  }

  // Calculate next review date based on quality (Spaced Repetition Algorithm)
  Flashcard updateReview(ReviewQuality quality) {
    int newInterval;
    double newEaseFactor = easeFactor;

    switch (quality) {
      case ReviewQuality.again:
        newInterval = 1;
        newEaseFactor = (easeFactor - 0.2).clamp(1.3, double.infinity);
        break;
      case ReviewQuality.hard:
        newInterval = (interval * 1.2).round().clamp(1, 365);
        newEaseFactor = (easeFactor - 0.15).clamp(1.3, double.infinity);
        break;
      case ReviewQuality.good:
        newInterval = (interval * easeFactor).round().clamp(1, 365);
        // Ease factor stays the same
        break;
      case ReviewQuality.easy:
        newInterval = (interval * easeFactor * 1.3).round().clamp(1, 365);
        newEaseFactor = (easeFactor + 0.15).clamp(1.3, double.infinity);
        break;
    }

    final nextDate = DateTime.now().add(Duration(days: newInterval));

    return copyWith(
      nextReviewDate: nextDate,
      reviewCount: reviewCount + 1,
      easeFactor: newEaseFactor,
      interval: newInterval,
      updatedAt: DateTime.now(),
    );
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';

enum ReviewQuality {
  again, // Không nhớ
  hard, // Khó
  good, // Tốt
  easy, // Dễ
}

enum FlashcardStatus {
  active,
  suspended,
  archived,
}

class Flashcard {
  final String id;
  final String bookId;
  final String? noteId;
  final String front; // Câu hỏi hoặc gợi ý
  final String back; // Câu trả lời
  final int? page;
  final DateTime? dueAt;
  final DateTime? lastReviewedAt;
  final int intervalDays;
  final double easeFactor; // Hệ số dễ dàng (Anki algorithm)
  final int reviewCount;
  final int lapseCount;
  final FlashcardStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Flashcard({
    required this.id,
    required this.bookId,
    this.noteId,
    required this.front,
    required this.back,
    this.page,
    this.dueAt,
    this.lastReviewedAt,
    this.intervalDays = 1,
    this.easeFactor = 2.5, // Default ease factor
    this.reviewCount = 0,
    this.lapseCount = 0,
    this.status = FlashcardStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'bookId': bookId,
      'noteId': noteId,
      'front': front,
      'back': back,
      'page': page,
      'dueAt': dueAt != null ? Timestamp.fromDate(dueAt!) : null,
      'lastReviewedAt': lastReviewedAt != null
          ? Timestamp.fromDate(lastReviewedAt!)
          : null,
      'intervalDays': intervalDays,
      'easeFactor': easeFactor,
      'reviewCount': reviewCount,
      'lapseCount': lapseCount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory Flashcard.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Flashcard(
      id: doc.id,
      bookId: data['bookId'] ?? '',
      noteId: data['noteId'],
      front: data['front'] ?? '',
      back: data['back'] ?? '',
      page: data['page'],
      dueAt: (data['dueAt'] as Timestamp?)?.toDate(),
      lastReviewedAt: (data['lastReviewedAt'] as Timestamp?)?.toDate(),
      intervalDays: data['intervalDays'] ?? 1,
      easeFactor: (data['easeFactor'] as num?)?.toDouble() ?? 2.5,
      reviewCount: data['reviewCount'] ?? 0,
      lapseCount: data['lapseCount'] ?? 0,
      status: FlashcardStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FlashcardStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create copy with updated fields
  Flashcard copyWith({
    String? id,
    String? bookId,
    String? noteId,
    String? front,
    String? back,
    int? page,
    DateTime? dueAt,
    DateTime? lastReviewedAt,
    int? intervalDays,
    double? easeFactor,
    int? reviewCount,
    int? lapseCount,
    FlashcardStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      noteId: noteId ?? this.noteId,
      front: front ?? this.front,
      back: back ?? this.back,
      page: page ?? this.page,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      reviewCount: reviewCount ?? this.reviewCount,
      lapseCount: lapseCount ?? this.lapseCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if card is due for review
  bool get isDue {
    if (dueAt == null || status != FlashcardStatus.active) {
      return false;
    }
    return DateTime.now().isAfter(dueAt!) ||
        DateTime.now().isAtSameMomentAs(dueAt!);
  }

  // Calculate next review date based on quality (Spaced Repetition Algorithm)
  Flashcard updateReview(ReviewQuality quality) {
    int newIntervalDays;
    double newEaseFactor = easeFactor;
    int newLapseCount = lapseCount;

    switch (quality) {
      case ReviewQuality.again:
        newIntervalDays = 1;
        newEaseFactor = (easeFactor - 0.2).clamp(1.3, double.infinity);
        newLapseCount = lapseCount + 1;
        break;
      case ReviewQuality.hard:
        newIntervalDays = (intervalDays * 1.2).round().clamp(1, 365);
        newEaseFactor = (easeFactor - 0.15).clamp(1.3, double.infinity);
        break;
      case ReviewQuality.good:
        newIntervalDays = (intervalDays * easeFactor).round().clamp(1, 365);
        // Ease factor stays the same
        break;
      case ReviewQuality.easy:
        newIntervalDays =
            (intervalDays * easeFactor * 1.3).round().clamp(1, 365);
        newEaseFactor = (easeFactor + 0.15).clamp(1.3, double.infinity);
        break;
    }

    final nextDueDate = DateTime.now().add(Duration(days: newIntervalDays));

    return copyWith(
      dueAt: nextDueDate,
      lastReviewedAt: DateTime.now(),
      reviewCount: reviewCount + 1,
      easeFactor: newEaseFactor,
      intervalDays: newIntervalDays,
      lapseCount: newLapseCount,
      updatedAt: DateTime.now(),
    );
  }
}


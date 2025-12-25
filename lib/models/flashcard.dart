import 'package:cloud_firestore/cloud_firestore.dart';

enum FlashcardStatus { due, done, later }

class Flashcard {
  final String id;
  final String userId;
  final String bookId;
  final String bookTitle;
  final String? noteId; // Optional: link to source note
  final String question;
  final String answer;
  final int timesReviewed;
  final FlashcardStatus status;
  final String level; // Easy/Medium/Hard
  final DateTime? nextReviewDate;
  
  // Spaced Repetition fields (Anki-like algorithm)
  final DateTime? dueAt; // Ngày đến hạn ôn tập
  final int intervalDays; // Số ngày giữa các lần ôn
  final double easeFactor; // Hệ số dễ dàng (default 2.5, tăng khi nhớ tốt)
  final int reviewCount; // Số lần đã ôn
  final DateTime? lastReviewedAt; // Lần cuối ôn tập
  
  final DateTime createdAt;
  final DateTime updatedAt;

  Flashcard({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.bookTitle,
    this.noteId,
    required this.question,
    required this.answer,
    required this.timesReviewed,
    required this.status,
    required this.level,
    this.nextReviewDate,
    this.dueAt,
    this.intervalDays = 1,
    this.easeFactor = 2.5,
    this.reviewCount = 0,
    this.lastReviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Flashcard copyWith({
    String? id,
    String? userId,
    String? bookId,
    String? bookTitle,
    String? noteId,
    String? question,
    String? answer,
    int? timesReviewed,
    FlashcardStatus? status,
    String? level,
    DateTime? nextReviewDate,
    DateTime? dueAt,
    int? intervalDays,
    double? easeFactor,
    int? reviewCount,
    DateTime? lastReviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      noteId: noteId ?? this.noteId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      timesReviewed: timesReviewed ?? this.timesReviewed,
      status: status ?? this.status,
      level: level ?? this.level,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      dueAt: dueAt ?? this.dueAt,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Firestore serialization
  factory Flashcard.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return Flashcard(
      id: documentId,
      userId: data['userId'] as String,
      bookId: data['bookId'] as String,
      bookTitle: data['bookTitle'] as String,
      noteId: data['noteId'] as String?,
      question: data['question'] as String,
      answer: data['answer'] as String,
      timesReviewed: data['timesReviewed'] as int? ?? 0,
      status: FlashcardStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'due'),
        orElse: () => FlashcardStatus.due,
      ),
      level: data['level'] as String? ?? 'Easy',
      nextReviewDate: _parseTimestamp(data['nextReviewDate']),
      dueAt: _parseTimestamp(data['dueAt']),
      intervalDays: (data['intervalDays'] as num?)?.toInt() ?? 1,
      easeFactor: (data['easeFactor'] as num?)?.toDouble() ?? 2.5,
      reviewCount: (data['reviewCount'] as int?) ?? 0,
      lastReviewedAt: _parseTimestamp(data['lastReviewedAt']),
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'noteId': noteId,
      'question': question,
      'answer': answer,
      'timesReviewed': timesReviewed,
      'status': status.name,
      'level': level,
      'nextReviewDate': nextReviewDate,
      'dueAt': dueAt,
      'intervalDays': intervalDays,
      'easeFactor': easeFactor,
      'reviewCount': reviewCount,
      'lastReviewedAt': lastReviewedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // JSON serialization (for backwards compatibility)
  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      userId: json['userId'] as String,
      bookId: json['bookId'] as String,
      bookTitle: json['bookTitle'] as String,
      noteId: json['noteId'] as String?,
      question: json['question'] as String,
      answer: json['answer'] as String,
      timesReviewed: json['timesReviewed'] as int? ?? 0,
      status: FlashcardStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'due'),
        orElse: () => FlashcardStatus.due,
      ),
      level: json['level'] as String? ?? 'Easy',
      nextReviewDate: json['nextReviewDate'] != null
          ? DateTime.parse(json['nextReviewDate'] as String)
          : null,
      dueAt: json['dueAt'] != null
          ? DateTime.parse(json['dueAt'] as String)
          : null,
      intervalDays: (json['intervalDays'] as num?)?.toInt() ?? 1,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      reviewCount: (json['reviewCount'] as int?) ?? 0,
      lastReviewedAt: json['lastReviewedAt'] != null
          ? DateTime.parse(json['lastReviewedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'noteId': noteId,
      'question': question,
      'answer': answer,
      'timesReviewed': timesReviewed,
      'status': status.name,
      'level': level,
      'nextReviewDate': nextReviewDate?.toIso8601String(),
      'dueAt': dueAt?.toIso8601String(),
      'intervalDays': intervalDays,
      'easeFactor': easeFactor,
      'reviewCount': reviewCount,
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    try {
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      return null;
    } catch (e) {
      return null;
    }
  }
}

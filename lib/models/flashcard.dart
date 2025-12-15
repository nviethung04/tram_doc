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
      nextReviewDate: data['nextReviewDate'] != null
          ? (data['nextReviewDate'] as dynamic).toDate()
          : null,
      createdAt: (data['createdAt'] as dynamic).toDate(),
      updatedAt: (data['updatedAt'] as dynamic).toDate(),
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

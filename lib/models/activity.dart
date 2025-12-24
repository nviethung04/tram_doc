enum ActivityType { bookAdded, bookFinished, noteCreated, flashcardCreated }

class Activity {
  final String id;
  final String userId;
  final ActivityType type;
  final String? bookId;
  final String? bookTitle;
  final String? noteId;
  final String? flashcardId;
  final String? message;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  Activity({
    required this.id,
    required this.userId,
    required this.type,
    this.bookId,
    this.bookTitle,
    this.noteId,
    this.flashcardId,
    this.message,
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Activity copyWith({
    String? id,
    String? userId,
    ActivityType? type,
    String? bookId,
    String? bookTitle,
    String? noteId,
    String? flashcardId,
    String? message,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Activity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      noteId: noteId ?? this.noteId,
      flashcardId: flashcardId ?? this.flashcardId,
      message: message ?? this.message,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Activity.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Activity(
      id: documentId,
      userId: data['userId'] as String,
      type: ActivityType.values.firstWhere(
        (e) => e.name == (data['type'] as String? ?? 'bookAdded'),
        orElse: () => ActivityType.bookAdded,
      ),
      bookId: data['bookId'] as String?,
      bookTitle: data['bookTitle'] as String?,
      noteId: data['noteId'] as String?,
      flashcardId: data['flashcardId'] as String?,
      message: data['message'] as String?,
      isPublic: data['isPublic'] as bool? ?? false,
      createdAt: (data['createdAt'] as dynamic).toDate(),
      updatedAt: (data['updatedAt'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'noteId': noteId,
      'flashcardId': flashcardId,
      'message': message,
      'isPublic': isPublic,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}


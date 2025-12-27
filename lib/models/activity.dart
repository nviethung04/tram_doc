enum ActivityType { bookAdded, bookFinished, noteCreated, flashcardCreated }

class Activity {
  final String id;
  final String userId;
  final ActivityType type;
  final String? kind;
  final String? bookId;
  final String? bookTitle;
  final String? userBookId;
  final String? noteId;
  final String? flashcardId;
  final String? message;
  final int? rating;
  final bool isPublic;
  final String? visibility;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Activity({
    required this.id,
    required this.userId,
    required this.type,
    this.kind,
    this.bookId,
    this.bookTitle,
    this.userBookId,
    this.noteId,
    this.flashcardId,
    this.message,
    this.rating,
    this.isPublic = false,
    this.visibility,
    this.likeCount = 0,
    this.commentCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Activity copyWith({
    String? id,
    String? userId,
    ActivityType? type,
    String? kind,
    String? bookId,
    String? bookTitle,
    String? userBookId,
    String? noteId,
    String? flashcardId,
    String? message,
    int? rating,
    bool? isPublic,
    String? visibility,
    int? likeCount,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Activity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      kind: kind ?? this.kind,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      userBookId: userBookId ?? this.userBookId,
      noteId: noteId ?? this.noteId,
      flashcardId: flashcardId ?? this.flashcardId,
      message: message ?? this.message,
      rating: rating ?? this.rating,
      isPublic: isPublic ?? this.isPublic,
      visibility: visibility ?? this.visibility,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Activity.fromFirestore(Map<String, dynamic> data, String documentId) {
    final rawType = data['type'] ?? data['kind'];
    final String visibility = (data['visibility'] as String?) ??
        ((data['isPublic'] as bool?) == true ? 'public' : 'private');
    return Activity(
      id: documentId,
      userId: (data['userId'] ?? '') as String,
      type: ActivityType.values.firstWhere(
        (e) => e.name == (rawType as String? ?? 'bookAdded'),
        orElse: () => ActivityType.bookAdded,
      ),
      kind: data['kind'] as String?,
      bookId: data['bookId'] as String?,
      bookTitle: data['bookTitle'] as String?,
      userBookId: data['userBookId'] as String?,
      noteId: data['noteId'] as String?,
      flashcardId: data['flashcardId'] as String?,
      message: data['message'] as String?,
      rating: (data['rating'] as num?)?.toInt(),
      isPublic: (data['isPublic'] as bool?) ?? (visibility == 'public'),
      visibility: visibility,
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as dynamic).toDate(),
      updatedAt: (data['updatedAt'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final visibilityValue = visibility ?? (isPublic ? 'public' : 'private');
    return {
      'userId': userId,
      'type': type.name,
      'kind': kind ?? type.name,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'userBookId': userBookId,
      'noteId': noteId,
      'flashcardId': flashcardId,
      'message': message,
      'rating': rating,
      'isPublic': isPublic,
      'visibility': visibilityValue,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}


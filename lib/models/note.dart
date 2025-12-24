class Note {
  final String id;
  final String userId;
  final String bookId;
  final String bookTitle;
  final String content;
  final int? page;
  final bool isKeyIdea;
  final bool isFlashcard;
  
  // OCR fields
  final String? imageUrl; // URL của ảnh đã upload
  final String? ocrText; // Text được extract từ OCR
  
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.bookTitle,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.page,
    this.isKeyIdea = false,
    this.isFlashcard = false,
    this.imageUrl,
    this.ocrText,
  });

  Note copyWith({
    String? id,
    String? userId,
    String? bookId,
    String? bookTitle,
    String? content,
    int? page,
    bool? isKeyIdea,
    bool? isFlashcard,
    String? imageUrl,
    String? ocrText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      content: content ?? this.content,
      page: page ?? this.page,
      isKeyIdea: isKeyIdea ?? this.isKeyIdea,
      isFlashcard: isFlashcard ?? this.isFlashcard,
      imageUrl: imageUrl ?? this.imageUrl,
      ocrText: ocrText ?? this.ocrText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Firestore serialization
  factory Note.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Note(
      id: documentId,
      userId: data['userId'] as String,
      bookId: data['bookId'] as String,
      bookTitle: data['bookTitle'] as String,
      content: data['content'] as String,
      page: data['page'] as int?,
      isKeyIdea: data['isKeyIdea'] as bool? ?? false,
      isFlashcard: data['isFlashcard'] as bool? ?? false,
      imageUrl: data['imageUrl'] as String?,
      ocrText: data['ocrText'] as String?,
      createdAt: (data['createdAt'] as dynamic).toDate(),
      updatedAt: (data['updatedAt'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'content': content,
      'page': page,
      'isKeyIdea': isKeyIdea,
      'isFlashcard': isFlashcard,
      'imageUrl': imageUrl,
      'ocrText': ocrText,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // JSON serialization (for backwards compatibility)
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      userId: json['userId'] as String,
      bookId: json['bookId'] as String,
      bookTitle: json['bookTitle'] as String,
      content: json['content'] as String,
      page: json['page'] as int?,
      isKeyIdea: json['isKeyIdea'] as bool? ?? false,
      isFlashcard: json['isFlashcard'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      ocrText: json['ocrText'] as String?,
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
      'content': content,
      'page': page,
      'isKeyIdea': isKeyIdea,
      'isFlashcard': isFlashcard,
      'imageUrl': imageUrl,
      'ocrText': ocrText,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

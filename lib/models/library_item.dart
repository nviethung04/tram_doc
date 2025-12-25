class LibraryItem {
  final String id;
  final String userId;
  final String bookId;
  final bool isPublic; // Có thể share với bạn bè
  final DateTime addedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  LibraryItem({
    required this.id,
    required this.userId,
    required this.bookId,
    this.isPublic = false,
    required this.addedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  LibraryItem copyWith({
    String? id,
    String? userId,
    String? bookId,
    bool? isPublic,
    DateTime? addedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LibraryItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      isPublic: isPublic ?? this.isPublic,
      addedAt: addedAt ?? this.addedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory LibraryItem.fromFirestore(Map<String, dynamic> data, String documentId) {
    return LibraryItem(
      id: documentId,
      userId: data['userId'] as String,
      bookId: data['bookId'] as String,
      isPublic: data['isPublic'] as bool? ?? false,
      addedAt: (data['addedAt'] as dynamic).toDate(),
      createdAt: (data['createdAt'] as dynamic).toDate(),
      updatedAt: (data['updatedAt'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'bookId': bookId,
      'isPublic': isPublic,
      'addedAt': addedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}



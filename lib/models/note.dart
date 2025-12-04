import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String bookId;
  final String userId;
  final String content;
  final int? pageNumber;
  final String? imageUrl; // OCR image
  final List<String> tags;
  final bool isKeyTakeaway; // Ý tưởng cốt lõi
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.content,
    this.pageNumber,
    this.imageUrl,
    this.tags = const [],
    this.isKeyTakeaway = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'bookId': bookId,
      'userId': userId,
      'content': content,
      'pageNumber': pageNumber,
      'imageUrl': imageUrl,
      'tags': tags,
      'isKeyTakeaway': isKeyTakeaway,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id: data['id'] ?? doc.id,
      bookId: data['bookId'] ?? '',
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      pageNumber: data['pageNumber'],
      imageUrl: data['imageUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      isKeyTakeaway: data['isKeyTakeaway'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create copy with updated fields
  Note copyWith({
    String? id,
    String? bookId,
    String? userId,
    String? content,
    int? pageNumber,
    String? imageUrl,
    List<String>? tags,
    bool? isKeyTakeaway,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      pageNumber: pageNumber ?? this.pageNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      isKeyTakeaway: isKeyTakeaway ?? this.isKeyTakeaway,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


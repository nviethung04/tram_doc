import 'package:cloud_firestore/cloud_firestore.dart';

enum NoteType {
  text,
  ocr,
  highlight,
}

class Note {
  final String id;
  final String bookId;
  final String? userBookId;
  final NoteType type;
  final String content;
  final int? page;
  final String? chapter;
  final String? imageUrl;
  final String? ocrRawText;
  final bool isKeyIdea;
  final int? keyIdeaOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.bookId,
    this.userBookId,
    required this.type,
    required this.content,
    this.page,
    this.chapter,
    this.imageUrl,
    this.ocrRawText,
    this.isKeyIdea = false,
    this.keyIdeaOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'bookId': bookId,
      'userBookId': userBookId,
      'type': type.name,
      'content': content,
      'page': page,
      'chapter': chapter,
      'imageUrl': imageUrl,
      'ocrRawText': ocrRawText,
      'isKeyIdea': isKeyIdea,
      'keyIdeaOrder': keyIdeaOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      bookId: data['bookId'] ?? '',
      userBookId: data['userBookId'],
      type: NoteType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NoteType.text,
      ),
      content: data['content'] ?? '',
      page: data['page'],
      chapter: data['chapter'],
      imageUrl: data['imageUrl'],
      ocrRawText: data['ocrRawText'],
      isKeyIdea: data['isKeyIdea'] ?? false,
      keyIdeaOrder: data['keyIdeaOrder'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create copy with updated fields
  Note copyWith({
    String? id,
    String? bookId,
    String? userBookId,
    NoteType? type,
    String? content,
    int? page,
    String? chapter,
    String? imageUrl,
    String? ocrRawText,
    bool? isKeyIdea,
    int? keyIdeaOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      userBookId: userBookId ?? this.userBookId,
      type: type ?? this.type,
      content: content ?? this.content,
      page: page ?? this.page,
      chapter: chapter ?? this.chapter,
      imageUrl: imageUrl ?? this.imageUrl,
      ocrRawText: ocrRawText ?? this.ocrRawText,
      isKeyIdea: isKeyIdea ?? this.isKeyIdea,
      keyIdeaOrder: keyIdeaOrder ?? this.keyIdeaOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


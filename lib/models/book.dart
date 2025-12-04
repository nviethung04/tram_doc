import 'package:cloud_firestore/cloud_firestore.dart';

enum BookStatus {
  wantToRead,
  reading,
  read,
}

enum BookType {
  physical,
  ebook,
}

class Book {
  final String id;
  final String title;
  final String? author;
  final String? isbn;
  final String? coverUrl;
  final String? description;
  final BookStatus status;
  final BookType type;
  final int? totalPages;
  final int? currentPage;
  final String? physicalLocation; // Vị trí sách giấy
  final String? borrowedTo; // Cho ai mượn
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;

  Book({
    required this.id,
    required this.title,
    this.author,
    this.isbn,
    this.coverUrl,
    this.description,
    required this.status,
    required this.type,
    this.totalPages,
    this.currentPage,
    this.physicalLocation,
    this.borrowedTo,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'coverUrl': coverUrl,
      'description': description,
      'status': status.name,
      'type': type.name,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'physicalLocation': physicalLocation,
      'borrowedTo': borrowedTo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
    };
  }

  // Create from Firestore document
  factory Book.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Book(
      id: data['id'] ?? doc.id,
      title: data['title'] ?? '',
      author: data['author'],
      isbn: data['isbn'],
      coverUrl: data['coverUrl'],
      description: data['description'],
      status: BookStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookStatus.wantToRead,
      ),
      type: BookType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => BookType.physical,
      ),
      totalPages: data['totalPages'],
      currentPage: data['currentPage'],
      physicalLocation: data['physicalLocation'],
      borrowedTo: data['borrowedTo'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data['userId'] ?? '',
    );
  }

  // Create copy with updated fields
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? isbn,
    String? coverUrl,
    String? description,
    BookStatus? status,
    BookType? type,
    int? totalPages,
    int? currentPage,
    String? physicalLocation,
    String? borrowedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      status: status ?? this.status,
      type: type ?? this.type,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      physicalLocation: physicalLocation ?? this.physicalLocation,
      borrowedTo: borrowedTo ?? this.borrowedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }

  // Get reading progress percentage
  double get progressPercentage {
    if (totalPages == null || totalPages == 0 || currentPage == null) {
      return 0.0;
    }
    return (currentPage! / totalPages!).clamp(0.0, 1.0);
  }
}


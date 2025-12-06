import 'package:cloud_firestore/cloud_firestore.dart';

enum BookSourceProvider {
  googleBooks,
  manual,
}

class BookSource {
  final BookSourceProvider provider;
  final String? externalId;

  BookSource({
    required this.provider,
    this.externalId,
  });

  Map<String, dynamic> toMap() {
    return {
      'provider': provider.name,
      'externalId': externalId,
    };
  }

  factory BookSource.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return BookSource(provider: BookSourceProvider.manual);
    }
    return BookSource(
      provider: BookSourceProvider.values.firstWhere(
        (e) => e.name == map['provider'],
        orElse: () => BookSourceProvider.manual,
      ),
      externalId: map['externalId'],
    );
  }
}

class Book {
  final String id;
  final String title;
  final String? subtitle;
  final List<String> authors;
  final String? publisher;
  final String? publishedDate;
  final String? description;
  final int? pageCount;
  final List<String> categories;
  final String? isbn10;
  final String? isbn13;
  final String? coverUrl;
  final BookSource source;
  final DateTime createdAt;
  final DateTime updatedAt;

  Book({
    required this.id,
    required this.title,
    this.subtitle,
    this.authors = const [],
    this.publisher,
    this.publishedDate,
    this.description,
    this.pageCount,
    this.categories = const [],
    this.isbn10,
    this.isbn13,
    this.coverUrl,
    BookSource? source,
    required this.createdAt,
    required this.updatedAt,
  }) : source = source ?? BookSource(provider: BookSourceProvider.manual);

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'authors': authors,
      'publisher': publisher,
      'publishedDate': publishedDate,
      'description': description,
      'pageCount': pageCount,
      'categories': categories,
      'isbn10': isbn10,
      'isbn13': isbn13,
      'coverUrl': coverUrl,
      'source': source.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory Book.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'],
      authors: List<String>.from(data['authors'] ?? []),
      publisher: data['publisher'],
      publishedDate: data['publishedDate'],
      description: data['description'],
      pageCount: data['pageCount'],
      categories: List<String>.from(data['categories'] ?? []),
      isbn10: data['isbn10'],
      isbn13: data['isbn13'],
      coverUrl: data['coverUrl'],
      source: BookSource.fromMap(data['source'] as Map<String, dynamic>?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create copy with updated fields
  Book copyWith({
    String? id,
    String? title,
    String? subtitle,
    List<String>? authors,
    String? publisher,
    String? publishedDate,
    String? description,
    int? pageCount,
    List<String>? categories,
    String? isbn10,
    String? isbn13,
    String? coverUrl,
    BookSource? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      authors: authors ?? this.authors,
      publisher: publisher ?? this.publisher,
      publishedDate: publishedDate ?? this.publishedDate,
      description: description ?? this.description,
      pageCount: pageCount ?? this.pageCount,
      categories: categories ?? this.categories,
      isbn10: isbn10 ?? this.isbn10,
      isbn13: isbn13 ?? this.isbn13,
      coverUrl: coverUrl ?? this.coverUrl,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

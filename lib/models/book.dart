import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum BookStatus { wantToRead, reading, read }

extension BookStatusX on BookStatus {
  String get label {
    switch (this) {
      case BookStatus.wantToRead:
        return 'Muốn đọc';
      case BookStatus.reading:
        return 'Đang đọc';
      case BookStatus.read:
        return 'Đã đọc';
    }
  }

  Color get color {
    switch (this) {
      case BookStatus.wantToRead:
        return AppColors.primary;
      case BookStatus.reading:
        return AppColors.accent;
      case BookStatus.read:
        return AppColors.success;
    }
  }

  static BookStatus fromName(String? name) {
    switch (name) {
      case 'reading':
        return BookStatus.reading;
      case 'read':
        return BookStatus.read;
      case 'wantToRead':
      default:
        return BookStatus.wantToRead;
    }
  }
}

class Book {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String? isbn;
  final BookStatus status;
  final int readPages;
  final int totalPages;
  final String description;
  final List<String> categories;
  final String? language;
  final int? publishedYear;
  final String? userId;

  double get progress => totalPages == 0 ? 0 : readPages / totalPages;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.status,
    required this.readPages,
    required this.totalPages,
    required this.description,
    this.coverUrl,
    this.isbn,
    this.categories = const [],
    this.language,
    this.publishedYear,
    this.userId,
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? coverUrl,
    String? isbn,
    BookStatus? status,
    int? readPages,
    int? totalPages,
    String? description,
    List<String>? categories,
    String? language,
    int? publishedYear,
    String? userId,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      status: status ?? this.status,
      readPages: readPages ?? this.readPages,
      totalPages: totalPages ?? this.totalPages,
      description: description ?? this.description,
      isbn: isbn ?? this.isbn,
      categories: categories ?? this.categories,
      language: language ?? this.language,
      publishedYear: publishedYear ?? this.publishedYear,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'isbn': isbn,
      'status': status.name,
      'readPages': readPages,
      'totalPages': totalPages,
      'description': description,
      'categories': categories,
      'language': language,
      'publishedYear': publishedYear,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Book.fromMap(Map<String, dynamic> map, String id) {
    return Book(
      id: id,
      title: (map['title'] as String?) ?? 'Chưa có tiêu đề',
      author: (map['author'] as String?) ?? 'Chưa rõ tác giả',
      coverUrl: map['coverUrl'] as String?,
      isbn: map['isbn'] as String?,
      status: BookStatusX.fromName(map['status'] as String?),
      readPages: (map['readPages'] as num?)?.toInt() ?? 0,
      totalPages: (map['totalPages'] as num?)?.toInt() ?? 0,
      description: (map['description'] as String?) ?? 'Chưa có mô tả',
      categories:
          (map['categories'] as List?)?.whereType<String>().toList() ??
              const [],
      language: map['language'] as String?,
      publishedYear: (map['publishedYear'] as num?)?.toInt(),
      userId: map['userId'] as String?,
    );
  }

  /// Parse a Google Books volume.
  factory Book.fromGoogleVolume(Map<String, dynamic> volume) {
    final info = (volume['volumeInfo'] as Map<String, dynamic>?) ?? {};
    final identifiers =
        (info['industryIdentifiers'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const [];
    String? isbn;
    for (final id in identifiers) {
      final value = id['identifier'] as String?;
      final type = (id['type'] as String?)?.toUpperCase();
      if (value == null) continue;
      if (type == 'ISBN_13') {
        isbn = value;
        break;
      }
      isbn ??= value;
    }

    final images = (info['imageLinks'] as Map<String, dynamic>?) ?? {};
    final authors = (info['authors'] as List?)?.whereType<String>().toList() ??
        const [];
    final title = (info['title'] as String?)?.trim();
    final desc = (info['description'] as String?)?.trim();
    final totalPages = info['pageCount'] is int ? info['pageCount'] as int : 0;
    final categories =
        (info['categories'] as List?)?.whereType<String>().toList() ??
            const [];
    final language = (info['language'] as String?)?.trim();
    final publishedDate = (info['publishedDate'] as String?)?.trim();
    final yearMatch = publishedDate == null
        ? null
        : RegExp(r'^(\d{4})').firstMatch(publishedDate);
    final publishedYear =
        yearMatch != null ? int.tryParse(yearMatch.group(1)!) : null;
    String? cover = (images['thumbnail'] ?? images['smallThumbnail']) as String?;
    if (cover != null && cover.startsWith('http://')) {
      cover = cover.replaceFirst(
        'http://',
        'https://',
      ); // Google Books trả http, Android 9+ chặn cleartext.
    }

    return Book(
      id: (volume['id'] as String?) ??
          isbn ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: (title?.isNotEmpty ?? false) ? title! : 'Chưa có tiêu đề',
      author: authors.isNotEmpty ? authors.join(', ') : 'Chưa rõ tác giả',
      coverUrl: cover,
      isbn: isbn,
      status: BookStatus.wantToRead,
      readPages: 0,
      totalPages: totalPages,
      description: (desc?.isNotEmpty ?? false) ? desc! : 'Chưa có mô tả',
      categories: categories,
      language: language,
      publishedYear: publishedYear,
    );
  }

  factory Book.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawStatus = data['status'];
    BookStatus status;
    if (rawStatus is int && rawStatus >= 0 && rawStatus < BookStatus.values.length) {
      status = BookStatus.values[rawStatus];
    } else if (rawStatus is String) {
      status = BookStatusX.fromName(rawStatus);
    } else {
      status = BookStatus.wantToRead;
    }

    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      coverUrl: data['coverUrl'],
      isbn: data['isbn'],
      status: status,
      readPages: (data['readPages'] as num?)?.toInt() ?? 0,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 0,
      description: data['description'] ?? '',
      categories:
          (data['categories'] as List?)?.whereType<String>().toList() ??
              const [],
      language: data['language'] as String?,
      publishedYear: (data['publishedYear'] as num?)?.toInt(),
      userId: data['userId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'isbn': isbn,
      'status': status.index,
      'readPages': readPages,
      'totalPages': totalPages,
      'description': description,
      'categories': categories,
      'language': language,
      'publishedYear': publishedYear,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

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
    );
  }

  factory Book.fromGoogleVolume(Map<String, dynamic> volume) {
    final info = (volume['volumeInfo'] as Map<String, dynamic>?) ?? {};
    final identifiers =
        (info['industryIdentifiers'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [];
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
    final authors = (info['authors'] as List?)?.whereType<String>().toList() ?? const [];
    final title = (info['title'] as String?)?.trim();
    final desc = (info['description'] as String?)?.trim();
    final totalPages = info['pageCount'] is int ? info['pageCount'] as int : 0;
    String? cover = (images['thumbnail'] ?? images['smallThumbnail']) as String?;
    if (cover != null && cover.startsWith('http://')) {
      cover = cover.replaceFirst('http://', 'https://'); // Google Books trả http, Android 9+ chặn cleartext.
    }

    return Book(
      id: (volume['id'] as String?) ?? isbn ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: (title?.isNotEmpty ?? false) ? title! : 'Chưa có tiêu đề',
      author: authors.isNotEmpty ? authors.join(', ') : 'Chưa rõ tác giả',
      coverUrl: cover,
      isbn: isbn,
      status: BookStatus.wantToRead,
      readPages: 0,
      totalPages: totalPages,
      description: (desc?.isNotEmpty ?? false) ? desc! : 'Chưa có mô tả',
    );
  }
}

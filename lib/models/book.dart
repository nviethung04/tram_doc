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
}

class Book {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
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
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? coverUrl,
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
    );
  }
}

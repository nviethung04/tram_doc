class User {
  final int id;
  final String email;
  final String username;
  final String? fullName;
  final String? avatar;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      fullName: json['full_name'],
      avatar: json['avatar'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'avatar': avatar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum BookStatus { wantToRead, reading, read }

extension BookStatusExtension on BookStatus {
  String get value {
    switch (this) {
      case BookStatus.wantToRead:
        return 'want_to_read';
      case BookStatus.reading:
        return 'reading';
      case BookStatus.read:
        return 'read';
    }
  }

  static BookStatus fromString(String value) {
    switch (value) {
      case 'want_to_read':
        return BookStatus.wantToRead;
      case 'reading':
        return BookStatus.reading;
      case 'read':
        return BookStatus.read;
      default:
        return BookStatus.wantToRead;
    }
  }
}

class Book {
  final int id;
  final int userId;
  final String? googleId;
  final String? isbn;
  final String title;
  final String? authors;
  final String? publisher;
  final String? publishDate;
  final String? description;
  final String? coverUrl;
  final int? pageCount;
  final BookStatus status;
  final int progress;
  final String? location;
  final int? rating;
  final DateTime? startDate;
  final DateTime? finishDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Book({
    required this.id,
    required this.userId,
    this.googleId,
    this.isbn,
    required this.title,
    this.authors,
    this.publisher,
    this.publishDate,
    this.description,
    this.coverUrl,
    this.pageCount,
    required this.status,
    this.progress = 0,
    this.location,
    this.rating,
    this.startDate,
    this.finishDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      userId: json['user_id'],
      googleId: json['google_id'],
      isbn: json['isbn'],
      title: json['title'],
      authors: json['authors'],
      publisher: json['publisher'],
      publishDate: json['publish_date'],
      description: json['description'],
      coverUrl: json['cover_url'],
      pageCount: json['page_count'],
      status: BookStatusExtension.fromString(json['status'] ?? 'want_to_read'),
      progress: json['progress'] ?? 0,
      location: json['location'],
      rating: json['rating'],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      finishDate: json['finish_date'] != null
          ? DateTime.parse(json['finish_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'google_id': googleId,
      'isbn': isbn,
      'title': title,
      'authors': authors,
      'publisher': publisher,
      'publish_date': publishDate,
      'description': description,
      'cover_url': coverUrl,
      'page_count': pageCount,
      'status': status.value,
      'progress': progress,
      'location': location,
      'rating': rating,
      'start_date': startDate?.toIso8601String(),
      'finish_date': finishDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Book copyWith({
    int? id,
    int? userId,
    String? googleId,
    String? isbn,
    String? title,
    String? authors,
    String? publisher,
    String? publishDate,
    String? description,
    String? coverUrl,
    int? pageCount,
    BookStatus? status,
    int? progress,
    String? location,
    int? rating,
    DateTime? startDate,
    DateTime? finishDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      googleId: googleId ?? this.googleId,
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      publisher: publisher ?? this.publisher,
      publishDate: publishDate ?? this.publishDate,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      pageCount: pageCount ?? this.pageCount,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      startDate: startDate ?? this.startDate,
      finishDate: finishDate ?? this.finishDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum NoteType { note, highlight, quote, takeaway }

extension NoteTypeExtension on NoteType {
  String get value {
    switch (this) {
      case NoteType.note:
        return 'note';
      case NoteType.highlight:
        return 'highlight';
      case NoteType.quote:
        return 'quote';
      case NoteType.takeaway:
        return 'takeaway';
    }
  }

  static NoteType fromString(String value) {
    switch (value) {
      case 'note':
        return NoteType.note;
      case 'highlight':
        return NoteType.highlight;
      case 'quote':
        return NoteType.quote;
      case 'takeaway':
        return NoteType.takeaway;
      default:
        return NoteType.note;
    }
  }
}

class Note {
  final int id;
  final int userId;
  final int bookId;
  final String content;
  final int? page;
  final NoteType type;
  final bool isFlashcard;
  final int reviewCount;
  final DateTime? nextReview;
  final double ease;
  final int interval;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Book? book;

  Note({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.content,
    this.page,
    required this.type,
    this.isFlashcard = false,
    this.reviewCount = 0,
    this.nextReview,
    this.ease = 2.5,
    this.interval = 0,
    required this.createdAt,
    required this.updatedAt,
    this.book,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'],
      content: json['content'],
      page: json['page'],
      type: NoteTypeExtension.fromString(json['type'] ?? 'note'),
      isFlashcard: json['is_flashcard'] ?? false,
      reviewCount: json['review_count'] ?? 0,
      nextReview: json['next_review'] != null
          ? DateTime.parse(json['next_review'])
          : null,
      ease: (json['ease'] ?? 2.5).toDouble(),
      interval: json['interval'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      book: json['book'] != null ? Book.fromJson(json['book']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'content': content,
      'page': page,
      'type': type.value,
      'is_flashcard': isFlashcard,
      'review_count': reviewCount,
      'next_review': nextReview?.toIso8601String(),
      'ease': ease,
      'interval': interval,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum ActivityType { addBook, finishBook, rateBook, addNote, startBook }

extension ActivityTypeExtension on ActivityType {
  String get value {
    switch (this) {
      case ActivityType.addBook:
        return 'add_book';
      case ActivityType.finishBook:
        return 'finish_book';
      case ActivityType.rateBook:
        return 'rate_book';
      case ActivityType.addNote:
        return 'add_note';
      case ActivityType.startBook:
        return 'start_book';
    }
  }

  static ActivityType fromString(String value) {
    switch (value) {
      case 'add_book':
        return ActivityType.addBook;
      case 'finish_book':
        return ActivityType.finishBook;
      case 'rate_book':
        return ActivityType.rateBook;
      case 'add_note':
        return ActivityType.addNote;
      case 'start_book':
        return ActivityType.startBook;
      default:
        return ActivityType.addBook;
    }
  }

  String get displayText {
    switch (this) {
      case ActivityType.addBook:
        return 'đã thêm sách';
      case ActivityType.finishBook:
        return 'đã đọc xong';
      case ActivityType.rateBook:
        return 'đã đánh giá';
      case ActivityType.addNote:
        return 'đã ghi chú';
      case ActivityType.startBook:
        return 'bắt đầu đọc';
    }
  }
}

class Activity {
  final int id;
  final int userId;
  final int? bookId;
  final ActivityType type;
  final String? content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;
  final Book? book;

  Activity({
    required this.id,
    required this.userId,
    this.bookId,
    required this.type,
    this.content,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.book,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'],
      type: ActivityTypeExtension.fromString(json['type']),
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      book: json['book'] != null ? Book.fromJson(json['book']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'type': type.value,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

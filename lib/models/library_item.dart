import 'package:cloud_firestore/cloud_firestore.dart';

enum LibraryStatus { wantToRead, reading, read }

enum BookFormat { paper, ebook, audiobook }

class LibraryItem {
  final String id;
  final String bookId;
  final LibraryStatus status;
  final int? currentPage;
  final int? totalPages;
  final double? progressPercent;
  final BookFormat? format;
  final String? locationNote;
  final String? borrowedTo;
  final int? rating;
  final String? review;
  final List<String> tags;
  final DateTime? addedAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime updatedAt;

  LibraryItem({
    required this.id,
    required this.bookId,
    required this.status,
    this.currentPage,
    this.totalPages,
    this.progressPercent,
    this.format,
    this.locationNote,
    this.borrowedTo,
    this.rating,
    this.review,
    this.tags = const [],
    this.addedAt,
    this.startedAt,
    this.finishedAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'bookId': bookId,
      'status': status.name,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'progressPercent': progressPercent,
      'format': format?.name,
      'locationNote': locationNote,
      'borrowedTo': borrowedTo,
      'rating': rating,
      'review': review,
      'tags': tags,
      'addedAt': addedAt != null ? Timestamp.fromDate(addedAt!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'finishedAt': finishedAt != null ? Timestamp.fromDate(finishedAt!) : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory LibraryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LibraryItem(
      id: doc.id,
      bookId: data['bookId'] ?? '',
      status: LibraryStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => LibraryStatus.wantToRead,
      ),
      currentPage: data['currentPage'],
      totalPages: data['totalPages'],
      progressPercent: (data['progressPercent'] as num?)?.toDouble(),
      format: data['format'] != null
          ? BookFormat.values.firstWhere(
              (e) => e.name == data['format'],
              orElse: () => BookFormat.paper,
            )
          : null,
      locationNote: data['locationNote'],
      borrowedTo: data['borrowedTo'],
      rating: data['rating'],
      review: data['review'],
      tags: List<String>.from(data['tags'] ?? []),
      addedAt: (data['addedAt'] as Timestamp?)?.toDate(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      finishedAt: (data['finishedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  LibraryItem copyWith({
    String? id,
    String? bookId,
    LibraryStatus? status,
    int? currentPage,
    int? totalPages,
    double? progressPercent,
    BookFormat? format,
    String? locationNote,
    String? borrowedTo,
    int? rating,
    String? review,
    List<String>? tags,
    DateTime? addedAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    DateTime? updatedAt,
  }) {
    return LibraryItem(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      status: status ?? this.status,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      progressPercent: progressPercent ?? this.progressPercent,
      format: format ?? this.format,
      locationNote: locationNote ?? this.locationNote,
      borrowedTo: borrowedTo ?? this.borrowedTo,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      tags: tags ?? this.tags,
      addedAt: addedAt ?? this.addedAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get calculatedProgressPercent {
    if (totalPages == null || totalPages == 0 || currentPage == null) {
      return 0.0;
    }
    return (currentPage! / totalPages!).clamp(0.0, 100.0);
  }
}

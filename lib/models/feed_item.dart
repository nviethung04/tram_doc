import 'book.dart';

enum FeedType { finished, added, note }

class FeedItem {
  final String user;
  final String message;
  final FeedType type;
  final Book book;
  final int? rating;
  final DateTime time;

  FeedItem({
    required this.user,
    required this.message,
    required this.type,
    required this.book,
    required this.time,
    this.rating,
  });
}

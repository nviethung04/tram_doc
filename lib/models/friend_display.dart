import 'friend.dart';

/// Model để hiển thị friend trong UI (kết hợp Friend + User info)
class FriendDisplay {
  final String id;
  final String name;
  final String headline;
  final String? currentBook;
  final FriendStatus status;

  FriendDisplay({
    required this.id,
    required this.name,
    required this.headline,
    this.currentBook,
    required this.status,
  });
}



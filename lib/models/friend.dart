enum FriendStatus { friend, pending, invited }

class Friend {
  final String name;
  final String headline;
  final String? currentBook;
  final FriendStatus status;

  Friend({
    required this.name,
    required this.headline,
    required this.status,
    this.currentBook,
  });
}

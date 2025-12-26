enum FriendStatus { pending, accepted, blocked, friend }

class Friend {
  final String id;
  final String userId; // User gửi request
  final String friendId; // User nhận request
  final FriendStatus status;
  final String? avatarUrl;

  Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    this.avatarUrl,
  });
}

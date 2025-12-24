enum FriendStatus { pending, accepted, blocked }

class Friend {
  final String id;
  final String userId; // User gửi request
  final String friendId; // User nhận request
  final FriendStatus status;
  final DateTime? requestedAt;
  final DateTime? acceptedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    this.requestedAt,
    this.acceptedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Friend copyWith({
    String? id,
    String? userId,
    String? friendId,
    FriendStatus? status,
    DateTime? requestedAt,
    DateTime? acceptedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Friend(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Friend.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Friend(
      id: documentId,
      userId: data['userId'] as String,
      friendId: data['friendId'] as String,
      status: FriendStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'pending'),
        orElse: () => FriendStatus.pending,
      ),
      requestedAt: data['requestedAt'] != null
          ? (data['requestedAt'] as dynamic).toDate()
          : null,
      acceptedAt: data['acceptedAt'] != null
          ? (data['acceptedAt'] as dynamic).toDate()
          : null,
      createdAt: (data['createdAt'] as dynamic).toDate(),
      updatedAt: (data['updatedAt'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'friendId': friendId,
      'status': status.name,
      'requestedAt': requestedAt,
      'acceptedAt': acceptedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

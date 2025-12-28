import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.bio,
    this.photoUrl,
    this.dailyReviewHour,
    this.timezone,
    this.pushToken,
    this.lastSeenFriendInvitesAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String displayName;
  final String email;
  final String? bio;
  final String? photoUrl;
  final int? dailyReviewHour;
  final String? timezone;
  final String? pushToken;
  final DateTime? lastSeenFriendInvitesAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      displayName: (data['displayName'] ?? '') as String,
      email: (data['email'] ?? data['e-mail'] ?? '') as String,
      bio: data['bio'] as String?,
      photoUrl: data['photoUrl'] as String?,
      dailyReviewHour: (data['dailyReviewHour'] as num?)?.toInt(),
      timezone: data['timezone'] as String?,
      pushToken: data['pushToken'] as String?,
      lastSeenFriendInvitesAt: _timestampToDateTime(
        data['lastSeenFriendInvitesAt'],
      ),
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      if (bio != null) 'bio': bio,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (dailyReviewHour != null) 'dailyReviewHour': dailyReviewHour,
      if (timezone != null) 'timezone': timezone,
      if (pushToken != null) 'pushToken': pushToken,
      if (lastSeenFriendInvitesAt != null)
        'lastSeenFriendInvitesAt': Timestamp.fromDate(
          lastSeenFriendInvitesAt!,
        ),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  AppUser copyWith({
    String? displayName,
    String? email,
    String? bio,
    String? photoUrl,
    int? dailyReviewHour,
    String? timezone,
    String? pushToken,
    DateTime? lastSeenFriendInvitesAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      dailyReviewHour: dailyReviewHour ?? this.dailyReviewHour,
      timezone: timezone ?? this.timezone,
      pushToken: pushToken ?? this.pushToken,
      lastSeenFriendInvitesAt:
          lastSeenFriendInvitesAt ?? this.lastSeenFriendInvitesAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _timestampToDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

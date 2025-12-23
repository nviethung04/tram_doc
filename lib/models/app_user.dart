import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String displayName;
  final String email;
  final String? bio;
  final String? photoUrl;
  final int? dailyReviewHour;
  final String? timezone;
  final String? pushToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.bio,
    this.photoUrl,
    this.dailyReviewHour,
    this.timezone,
    this.pushToken,
    this.createdAt,
    this.updatedAt,
  });

  /// ✅ DÙNG CHO FriendService (whereIn + map)
  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      displayName: (data['displayName'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      bio: data['bio'] as String?,
      photoUrl: data['photoUrl'] as String?,
      dailyReviewHour: (data['dailyReviewHour'] as num?)?.toInt(),
      timezone: data['timezone'] as String?,
      pushToken: data['pushToken'] as String?,
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  /// (Nếu bạn dùng trực tiếp DocumentSnapshot)
  factory AppUser.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return AppUser.fromMap(doc.id, doc.data() ?? {});
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      if (bio != null) 'bio': bio,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (dailyReviewHour != null) 'dailyReviewHour': dailyReviewHour,
      if (timezone != null) 'timezone': timezone,
      if (pushToken != null) 'pushToken': pushToken,
      if (createdAt != null)
        'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null)
        'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  static DateTime? _toDateTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  AppUser copyWith({
    String? id,
    String? displayName,
    String? email,
    ValueGetter<String?>? bio,
    ValueGetter<String?>? photoUrl,
    ValueGetter<int?>? dailyReviewHour,
    ValueGetter<String?>? timezone,
    ValueGetter<String?>? pushToken,
    ValueGetter<DateTime?>? createdAt,
    ValueGetter<DateTime?>? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio != null ? bio() : this.bio,
      photoUrl: photoUrl != null ? photoUrl() : this.photoUrl,
      dailyReviewHour:
          dailyReviewHour != null ? dailyReviewHour() : this.dailyReviewHour,
      timezone: timezone != null ? timezone() : this.timezone,
      pushToken: pushToken != null ? pushToken() : this.pushToken,
      createdAt: createdAt != null ? createdAt() : this.createdAt,
      updatedAt: updatedAt != null ? updatedAt() : this.updatedAt,
    );
  }
}

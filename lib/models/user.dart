import 'package:cloud_firestore/cloud_firestore.dart';

class UserNotifications {
  final bool dailyReviewEnabled;
  final int? dailyReviewHour;
  final String? pushToken;

  UserNotifications({
    this.dailyReviewEnabled = false,
    this.dailyReviewHour,
    this.pushToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'dailyReviewEnabled': dailyReviewEnabled,
      'dailyReviewHour': dailyReviewHour,
      'pushToken': pushToken,
    };
  }

  factory UserNotifications.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return UserNotifications();
    }
    return UserNotifications(
      dailyReviewEnabled: map['dailyReviewEnabled'] ?? false,
      dailyReviewHour: map['dailyReviewHour'],
      pushToken: map['pushToken'],
    );
  }
}

class UserStats {
  final int totalBooksAdded;
  final int totalBooksFinished;
  final int totalNotes;
  final int totalFlashcards;

  UserStats({
    this.totalBooksAdded = 0,
    this.totalBooksFinished = 0,
    this.totalNotes = 0,
    this.totalFlashcards = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalBooksAdded': totalBooksAdded,
      'totalBooksFinished': totalBooksFinished,
      'totalNotes': totalNotes,
      'totalFlashcards': totalFlashcards,
    };
  }

  factory UserStats.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return UserStats();
    }
    return UserStats(
      totalBooksAdded: map['totalBooksAdded'] ?? 0,
      totalBooksFinished: map['totalBooksFinished'] ?? 0,
      totalNotes: map['totalNotes'] ?? 0,
      totalFlashcards: map['totalFlashcards'] ?? 0,
    );
  }
}

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? timezone;
  final String? locale;
  final UserNotifications notifications;
  final UserStats stats;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.timezone,
    this.locale,
    UserNotifications? notifications,
    UserStats? stats,
    required this.createdAt,
    required this.updatedAt,
  })  : notifications = notifications ?? UserNotifications(),
        stats = stats ?? UserStats();

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'timezone': timezone,
      'locale': locale,
      'notifications': notifications.toMap(),
      'stats': stats.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      timezone: data['timezone'],
      locale: data['locale'],
      notifications: UserNotifications.fromMap(
        data['notifications'] as Map<String, dynamic>?,
      ),
      stats: UserStats.fromMap(data['stats'] as Map<String, dynamic>?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create copy with updated fields
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? timezone,
    String? locale,
    UserNotifications? notifications,
    UserStats? stats,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      timezone: timezone ?? this.timezone,
      locale: locale ?? this.locale,
      notifications: notifications ?? this.notifications,
      stats: stats ?? this.stats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


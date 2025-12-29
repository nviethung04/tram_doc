import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
import '../services/flashcard_service.dart';
import '../../models/app_notification.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final FlashcardService _flashcardService = FlashcardService();
  
  static const String _lastNotificationKey = 'last_daily_notification';
  static const String _notificationTimeKey = 'notification_time_hour';
  static const int _defaultNotificationHour = 9; // 9 AM

  /// Khởi tạo notification service
  Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Lấy FCM token
      final token = await _messaging.getToken();
      if (token != null && _auth.currentUser != null) {
        await _saveToken(token);
      }

      // Lắng nghe token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        if (_auth.currentUser != null) {
          _saveToken(newToken);
        }
      });
    }
  }

  /// Lưu FCM token vào user profile
  Future<void> _saveToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'pushToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  /// Set notification time (hour in 24-hour format)
  Future<void> setNotificationTime(int hour) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_notificationTimeKey, hour);
    } catch (e) {
      print('Error setting notification time: $e');
    }
  }
  
  /// Get notification time
  Future<int> getNotificationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_notificationTimeKey) ?? _defaultNotificationHour;
    } catch (e) {
      print('Error getting notification time: $e');
      return _defaultNotificationHour;
    }
  }
  
  /// Check if should send daily notification
  Future<bool> shouldSendDailyNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotificationStr = prefs.getString(_lastNotificationKey);
      final now = DateTime.now();
      final notificationHour = await getNotificationTime();
      
      if (lastNotificationStr == null) {
        return true; // Never sent before
      }
      
      final lastNotification = DateTime.parse(lastNotificationStr);
      final todayNotificationTime = DateTime(
        now.year,
        now.month,
        now.day,
        notificationHour,
      );
      
      // Send if:
      // 1. Last notification was before today's notification time
      // 2. Current time is after today's notification time
      return lastNotification.isBefore(todayNotificationTime) && 
             now.isAfter(todayNotificationTime);
    } catch (e) {
      print('Error checking daily notification: $e');
      return false;
    }
  }
  
  /// Create daily practice notification
  Future<void> createDailyPracticeNotification() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;
      
      // Check if should send notification
      if (!await shouldSendDailyNotification()) {
        return;
      }
      
      // Get due flashcards count
      final dueCards = await _flashcardService.getDueFlashcards();
      if (dueCards.isEmpty) {
        return; // Don't send notification if no cards due
      }
      
      // Create in-app notification
      final notificationData = {
        'recipientId': currentUserId,
        'actorId': 'system',
        'actorName': 'Hệ thống',
        'type': 'flashcard_reminder',
        'message': 'Bạn có ${dueCards.length} flashcard cần ôn tập hôm nay! 📚',
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('notifications').add(notificationData);
      
      // Update last notification time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastNotificationKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error creating daily notification: $e');
    }
  }
  
  /// Schedule daily check (should be called periodically, e.g., every hour)
  Future<void> checkAndSendDailyNotification() async {
    await createDailyPracticeNotification();
  }

  /// Setup background message handler
  static Future<void> setupBackgroundHandler() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}

/// Background message handler (phải là top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Xử lý notification khi app ở background
}


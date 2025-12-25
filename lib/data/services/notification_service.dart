import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

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

  /// Lấy số flashcards đến hạn và gửi notification
  Future<void> checkAndNotifyDueFlashcards() async {
    try {
      final user = await _userService.getCurrentUser();
      if (user == null || user.pushToken == null || user.pushToken!.isEmpty) {
        return;
      }

      // TODO: Gọi API để lấy số flashcards đến hạn
      // Hoặc sử dụng Cloud Function để gửi notification
      // Hiện tại chỉ là placeholder
    } catch (e) {
      print('Error checking due flashcards: $e');
    }
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


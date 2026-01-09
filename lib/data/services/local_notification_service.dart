import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'flashcard_service.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FlashcardService _flashcardService = FlashcardService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _reminderEnabledKey = 'reminder_enabled';
  static const String _reminderTimeKey = 'reminder_time';
  static const int _defaultHour = 9; // 9 AM
  static const int _defaultMinute = 0;

  /// Initialize local notifications
  Future<void> initialize() async {
    // Initialize timezones
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      // Request notification permission
      await androidImplementation.requestNotificationsPermission();

      // Request exact alarm permission for Android 12+
      final exactAlarmGranted = await androidImplementation
          .requestExactAlarmsPermission();
      print('[Notification] Exact alarm permission: $exactAlarmGranted');
    }

    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // TODO: Navigate to flashcard review screen
  }

  /// Check if reminder is enabled
  Future<bool> isReminderEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_reminderEnabledKey) ?? false;
    } catch (e) {
      print('Error checking reminder enabled: $e');
      return false;
    }
  }

  /// Get reminder time
  Future<Map<String, int>> getReminderTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString(_reminderTimeKey);

      if (timeString != null) {
        final parts = timeString.split(':');
        return {'hour': int.parse(parts[0]), 'minute': int.parse(parts[1])};
      }

      return {'hour': _defaultHour, 'minute': _defaultMinute};
    } catch (e) {
      print('Error getting reminder time: $e');
      return {'hour': _defaultHour, 'minute': _defaultMinute};
    }
  }

  /// Set reminder enabled
  Future<void> setReminderEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reminderEnabledKey, enabled);

      if (enabled) {
        await scheduleDailyReminder();
      } else {
        await cancelDailyReminder();
      }
    } catch (e) {
      print('Error setting reminder enabled: $e');
    }
  }

  /// Set reminder time and reschedule
  Future<void> setReminderTime(int hour, int minute) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_reminderTimeKey, '$hour:$minute');

      // Reschedule if enabled
      final enabled = await isReminderEnabled();
      if (enabled) {
        await scheduleDailyReminder();
      }
    } catch (e) {
      print('Error setting reminder time: $e');
    }
  }

  /// Schedule daily reminder
  Future<void> scheduleDailyReminder() async {
    try {
      // Cancel existing notification
      await _notifications.cancel(0);

      final time = await getReminderTime();
      final hour = time['hour']!;
      final minute = time['minute']!;

      final scheduledTime = _nextInstanceOfTime(hour, minute);
      print(
        '[Notification] Scheduling for: $scheduledTime (${scheduledTime.hour}:${scheduledTime.minute})',
      );

      // Schedule notification
      await _notifications.zonedSchedule(
        0, // notification id
        'Ôn tập Flashcard 📚',
        'Đã đến giờ ôn tập! Hãy kiểm tra các flashcard của bạn.',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'flashcard_reminder',
            'Nhắc nhở ôn tập',
            channelDescription: 'Thông báo nhắc nhở ôn tập flashcard hàng ngày',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print(
        '[Notification] Daily reminder scheduled successfully for $hour:$minute',
      );
    } catch (e) {
      print('[Notification] Error scheduling daily reminder: $e');
    }
  }

  /// Cancel daily reminder
  Future<void> cancelDailyReminder() async {
    try {
      await _notifications.cancel(0);
      print('Daily reminder cancelled');
    } catch (e) {
      print('Error cancelling daily reminder: $e');
    }
  }

  /// Get next instance of specific time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time is before now, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Show immediate test notification
  Future<void> showTestNotification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get due flashcards count
      final dueCards = await _flashcardService.getDueFlashcards();
      final count = dueCards.length;

      await _notifications.show(
        1, // different id for test
        'Thông báo thử nghiệm 🔔',
        count > 0
            ? 'Bạn có $count flashcard cần ôn tập!'
            : 'Chưa có flashcard nào cần ôn tập.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'flashcard_reminder',
            'Nhắc nhở ôn tập',
            channelDescription: 'Thông báo nhắc nhở ôn tập flashcard hàng ngày',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      print('Error showing test notification: $e');
    }
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Check scheduled notification status
  Future<void> checkScheduledNotifications() async {
    try {
      final pending = await getPendingNotifications();
      print('[Notification] Pending notifications: ${pending.length}');
      for (final notification in pending) {
        print(
          '[Notification] - ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}',
        );
      }
    } catch (e) {
      print('[Notification] Error checking notifications: $e');
    }
  }
}

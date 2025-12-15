import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _lastLoginKey = 'last_login_time';
  static const int _sessionDurationHours = 3;

  // Lưu thời gian đăng nhập
  Future<void> saveLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastLoginKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Xóa thời gian đăng nhập (khi đăng xuất)
  Future<void> clearLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastLoginKey);
  }

  // Kiểm tra session còn hợp lệ không (dưới 3 giờ)
  Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginTime = prefs.getInt(_lastLoginKey);

    if (lastLoginTime == null) return false;

    final lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginTime);
    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    return difference.inHours < _sessionDurationHours;
  }

  // Lấy thời gian còn lại của session
  Future<Duration?> getRemainingSessionTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginTime = prefs.getInt(_lastLoginKey);

    if (lastLoginTime == null) return null;

    final lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginTime);
    final sessionExpiry = lastLogin.add(
      const Duration(hours: _sessionDurationHours),
    );
    final now = DateTime.now();

    if (now.isBefore(sessionExpiry)) {
      return sessionExpiry.difference(now);
    }

    return null;
  }
}

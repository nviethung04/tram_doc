import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String adminEmail = 'admin@gmail.com';

  /// Kiểm tra xem user hiện tại có phải admin không
  bool isAdmin() {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.email?.toLowerCase() == adminEmail.toLowerCase();
  }

  /// Lấy email của user hiện tại
  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  /// Lấy user ID hiện tại
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}

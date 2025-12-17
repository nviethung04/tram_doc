import 'package:firebase_auth/firebase_auth.dart';

import '../../models/app_user.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // Stream để theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng nhập với email/password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (_) {
      throw 'Đã xảy ra lỗi không xác định';
    }
  }

  // Đăng ký với email/password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Cập nhật tên hiển thị và tạo hồ sơ Firestore
      await userCredential.user?.updateDisplayName(displayName);
      final user = userCredential.user;
      if (user != null) {
        await _userService.createUserProfile(user, displayName: displayName);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (_) {
      throw 'Đã xảy ra lỗi không xác định';
    }
  }

  Future<AppUser?> getCurrentUserProfile() => _userService.getCurrentUser();

  // Cập nhật hồ sơ
  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? photoUrl,
    String? email,
  }) {
    return _userService.updateProfile(
      displayName: displayName,
      bio: bio,
      photoUrl: photoUrl,
      email: email,
    );
  }

  // Đăng xuất
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      throw 'Không thể đăng xuất';
    }
  }

  // Gửi email đặt lại mật khẩu
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (_) {
      throw 'Không thể gửi email đặt lại mật khẩu';
    }
  }

  // Xử lý lỗi Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này';
      case 'wrong-password':
        return 'Mật khẩu không chính xác';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập chưa được kích hoạt';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau';
      case 'invalid-credential':
        return 'Thông tin đăng nhập không chính xác';
      default:
        return 'Lỗi: ${e.message ?? 'Không xác định'}';
    }
  }
}

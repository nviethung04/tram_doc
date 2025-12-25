import 'package:firebase_auth/firebase_auth.dart';

import '../../models/app_user.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // Lắng nghe trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng nhập bằng email/password và trả về UserCredential
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

  // Đăng ký với email/password và trả về UserCredential
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    String? photoUrl,
  }) async {
    final safeName = displayName.trim().isNotEmpty
        ? displayName.trim()
        : (email.contains('@') ? email.split('@').first : 'Người dùng');
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Cập nhật tên hiển thị và tạo hồ sơ Firestore
      final user = userCredential.user;
      if (user == null) {
        throw 'Không lấy được thông tin người dùng sau đăng ký';
      }

      await user.updateDisplayName(safeName);
      if (photoUrl != null && photoUrl.isNotEmpty) {
        await user.updatePhotoURL(photoUrl);
      }

      try {
        await _userService.createUserProfile(
          user,
          displayName: safeName,
          photoUrl: photoUrl,
        );
      } catch (e) {
        throw 'Không lưu được hồ sơ người dùng: $e';
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Đã xảy ra lỗi: $e';
    }
  }

  /// Đăng ký và trả về AppUser (đầy đủ thông tin kèm lưu Firestore)
  Future<AppUser?> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
    String? photoUrl,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = result.user;
      if (user == null) {
        throw 'Không lấy được thông tin người dùng sau đăng ký';
      }

      final displayName = name.trim().isNotEmpty
          ? name.trim()
          : (email.contains('@') ? email.split('@').first : 'Người dùng');
      await user.updateDisplayName(displayName);
      if (photoUrl != null && photoUrl.isNotEmpty) {
        await user.updatePhotoURL(photoUrl);
      }
      await _userService.createUserProfile(
        user,
        displayName: displayName,
        photoUrl: photoUrl,
      );
      return await getUserData(user.uid);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Đăng ký thất bại';
    } catch (e) {
      throw 'Đăng ký thất bại: $e';
    }
  }

  Future<AppUser?> getCurrentUserProfile() => _userService.getCurrentUser();

  /// Lấy hồ sơ user theo uid
  Future<AppUser?> getUserData(String uid) => _userService.getUserById(uid);

  /// Đăng nhập và trả về AppUser
  Future<AppUser?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return await getUserData(result.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Đăng nhập thất bại';
    } catch (e) {
      throw 'Đăng nhập thất bại: $e';
    }
  }

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
        return 'Lỗi: ${e.message ?? "Không xác định"}';
    }
  }
}

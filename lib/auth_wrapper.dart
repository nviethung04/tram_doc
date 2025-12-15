import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';
import '../data/services/session_manager.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/app_shell.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final sessionManager = SessionManager();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Kiểm tra user đã đăng nhập chưa
        final user = snapshot.data;

        if (user == null) {
          // Chưa đăng nhập -> về màn hình login
          return const LoginScreen();
        }

        // Đã đăng nhập -> kiểm tra session timeout
        return FutureBuilder<bool>(
          future: sessionManager.isSessionValid(),
          builder: (context, sessionSnapshot) {
            if (sessionSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final isSessionValid = sessionSnapshot.data ?? false;

            if (!isSessionValid) {
              // Session đã hết hạn (quá 3 giờ) -> đăng xuất và về login
              authService.signOut();
              return const LoginScreen();
            }

            // Session còn hợp lệ -> vào app
            return const AppShell();
          },
        );
      },
    );
  }
}

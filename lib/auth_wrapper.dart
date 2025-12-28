import 'package:flutter/material.dart';

import '../data/services/auth_service.dart';
import '../data/services/notification_service.dart';
import '../data/services/session_manager.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/app_shell.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  final _sessionManager = SessionManager();
  final _notificationService = NotificationService();
  bool _notificationsInitialized = false;

  late Future<bool> _onboardingFuture;

  @override
  void initState() {
    super.initState();
    _onboardingFuture = _sessionManager.isOnboardingDone();
  }

  void _finishOnboarding() async {
    await _sessionManager.completeOnboarding();
    setState(() {
      _onboardingFuture = Future.value(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _onboardingFuture,
      builder: (context, onboardingSnapshot) {
        if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final onboardingDone = onboardingSnapshot.data ?? false;
        if (!onboardingDone) {
          return OnboardingScreen(onFinished: _finishOnboarding);
        }

        return StreamBuilder(
          stream: _authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final user = snapshot.data;

            if (user == null) {
              _notificationsInitialized = false;
              return const LoginScreen();
            }

            if (!_notificationsInitialized) {
              _notificationsInitialized = true;
              _notificationService.initialize();
            }

            return FutureBuilder<bool>(
              future: _sessionManager.isSessionValid(),
              builder: (context, sessionSnapshot) {
                if (sessionSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final isSessionValid = sessionSnapshot.data ?? false;

                if (!isSessionValid) {
                  _authService.signOut();
                  return const LoginScreen();
                }

                return const AppShell();
              },
            );
          },
        );
      },
    );
  }
}

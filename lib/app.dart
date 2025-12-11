import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';

class TramDocApp extends StatelessWidget {
  const TramDocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trạm Đọc',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const OnboardingScreen(),
    );
  }
}

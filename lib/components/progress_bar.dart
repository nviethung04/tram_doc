import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProgressBar extends StatelessWidget {
  final double value; // 0..1
  const ProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 8,
        child: LinearProgressIndicator(
          value: safeValue,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 8,
        ),
      ),
    );
  }
}

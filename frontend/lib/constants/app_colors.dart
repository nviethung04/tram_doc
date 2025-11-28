import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2E7D8B);
  static const Color primaryDark = Color(0xFF1F5D6B);
  static const Color primaryLight = Color(0xFF4A9FB0);

  static const Color secondary = Color(0xFFE8A317);
  static const Color secondaryDark = Color(0xFFCD8F00);
  static const Color secondaryLight = Color(0xFFFBC02D);

  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  static const Color text = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textLight = Color(0xFF9E9E9E);

  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);
  static const Color info = Color(0xFF17A2B8);

  static const Color cardShadow = Color(0x0D000000);
  static const Color divider = Color(0xFFE9ECEF);

  // Book status colors
  static const Color wantToReadColor = Color(0xFF6C757D);
  static const Color readingColor = Color(0xFF007BFF);
  static const Color readColor = Color(0xFF28A745);

  // Rating colors
  static const Color starColor = Color(0xFFFFD700);
  static const Color starEmptyColor = Color(0xFFE0E0E0);
}

class AppDimensions {
  static const double padding = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double margin = 16.0;
  static const double marginSmall = 8.0;
  static const double marginLarge = 24.0;
  static const double marginXLarge = 32.0;

  static const double borderRadius = 8.0;
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusLarge = 16.0;

  static const double iconSize = 24.0;
  static const double iconSizeSmall = 16.0;
  static const double iconSizeLarge = 32.0;

  static const double cardElevation = 2.0;
  static const double cardElevationHigh = 8.0;
}

class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.text,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.surface,
  );
}

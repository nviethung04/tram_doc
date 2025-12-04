import 'package:uuid/uuid.dart';

class Helpers {
  static const _uuid = Uuid();

  /// Generate unique ID
  static String generateId() {
    return _uuid.v4();
  }

  /// Format date to Vietnamese format
  static String formatDate(DateTime date) {
    // TODO: Use intl package for proper localization
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Format date time to Vietnamese format
  static String formatDateTime(DateTime date) {
    // TODO: Use intl package for proper localization
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Calculate reading progress percentage
  static double calculateProgress(int? currentPage, int? totalPages) {
    if (totalPages == null || totalPages == 0 || currentPage == null) {
      return 0.0;
    }
    return (currentPage / totalPages).clamp(0.0, 1.0);
  }

  /// Format progress as percentage string
  static String formatProgress(double progress) {
    return '${(progress * 100).toStringAsFixed(0)}%';
  }
}


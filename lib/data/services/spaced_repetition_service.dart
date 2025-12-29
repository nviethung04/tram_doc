import '../../models/flashcard.dart';

/// Service xử lý thuật toán Spaced Repetition (Anki-like)
class SpacedRepetitionService {
  // Constants cho thuật toán Anki
  static const double initialEaseFactor = 2.5;
  static const int initialInterval = 1; // 1 ngày
  static const double easeFactorMin = 1.3;
  static const double easeFactorMax = 2.5;
  static const double easeFactorChange = 0.15;

  // Số lần ôn tập tối đa trước khi tự động xóa flashcard (5 lần)
  static const int maxReviewsBeforeAutoDelete = 5;

  /// Tính toán thời gian ôn tập tiếp theo dựa trên quality (0-5)
  /// Quality: 0=again, 1=hard, 2=good, 3=easy
  static Map<String, dynamic> calculateNextReview({
    required int quality, // 0-3
    required int currentInterval,
    required double currentEaseFactor,
    required int reviewCount,
  }) {
    double newEaseFactor = currentEaseFactor;
    int newInterval = currentInterval;
    DateTime now = DateTime.now();

    // Cập nhật ease factor dựa trên quality
    if (quality == 0) {
      // Again - reset về ban đầu
      newEaseFactor = (currentEaseFactor - 0.2).clamp(
        easeFactorMin,
        easeFactorMax,
      );
      newInterval = 1;
    } else if (quality == 1) {
      // Hard - giảm ease factor
      newEaseFactor = (currentEaseFactor - 0.15).clamp(
        easeFactorMin,
        easeFactorMax,
      );
      newInterval = (currentInterval * 1.2).round().clamp(1, 365);
    } else if (quality == 2) {
      // Good - giữ nguyên ease factor
      newEaseFactor = currentEaseFactor;
      if (reviewCount == 0) {
        newInterval = 1;
      } else if (reviewCount == 1) {
        newInterval = 6;
      } else {
        newInterval = (currentInterval * newEaseFactor).round().clamp(1, 365);
      }
    } else if (quality == 3) {
      // Easy - tăng ease factor
      newEaseFactor = (currentEaseFactor + 0.15).clamp(
        easeFactorMin,
        easeFactorMax,
      );
      if (reviewCount == 0) {
        newInterval = 4;
      } else if (reviewCount == 1) {
        newInterval = 10;
      } else {
        newInterval = (currentInterval * newEaseFactor).round().clamp(1, 365);
      }
    }

    // Tính dueAt (ngày đến hạn)
    DateTime dueAt = now.add(Duration(days: newInterval));

    return {
      'intervalDays': newInterval,
      'easeFactor': newEaseFactor,
      'dueAt': dueAt,
      'nextReviewDate': dueAt,
      'reviewCount': reviewCount + 1,
      'lastReviewedAt': now,
    };
  }

  /// Tạo flashcard mới với spaced repetition fields
  static Flashcard initializeFlashcard(Flashcard flashcard) {
    final now = DateTime.now();
    return flashcard.copyWith(
      dueAt: now,
      intervalDays: initialInterval,
      easeFactor: initialEaseFactor,
      reviewCount: 0,
      nextReviewDate: now,
      status: FlashcardStatus.due,
    );
  }

  /// Cập nhật flashcard sau khi review
  /// Returns updated flashcard and a flag indicating if it should be deleted
  static Map<String, dynamic> updateAfterReview({
    required Flashcard flashcard,
    required int quality, // 0=again, 1=hard, 2=good, 3=easy
  }) {
    final result = calculateNextReview(
      quality: quality,
      currentInterval: flashcard.intervalDays,
      currentEaseFactor: flashcard.easeFactor,
      reviewCount: flashcard.reviewCount,
    );

    // Xác định status dựa trên quality
    FlashcardStatus newStatus;
    if (quality == 0) {
      newStatus = FlashcardStatus.due; // Again - cần ôn lại ngay
    } else if (quality == 1) {
      newStatus = FlashcardStatus.due; // Hard - vẫn cần ôn
    } else {
      newStatus = FlashcardStatus.done; // Good/Easy - đã xong
    }

    final updatedFlashcard = flashcard.copyWith(
      intervalDays: result['intervalDays'] as int,
      easeFactor: result['easeFactor'] as double,
      dueAt: result['dueAt'] as DateTime,
      nextReviewDate: result['nextReviewDate'] as DateTime,
      reviewCount: result['reviewCount'] as int,
      lastReviewedAt: result['lastReviewedAt'] as DateTime,
      status: newStatus,
      timesReviewed: flashcard.timesReviewed + 1,
    );

    // Check if flashcard should be auto-deleted
    // Xóa nếu đã ôn >= maxReviewsBeforeAutoDelete lần VÀ quality tốt (good hoặc easy)
    final shouldDelete =
        updatedFlashcard.reviewCount >= maxReviewsBeforeAutoDelete &&
        quality >= 2;

    return {'flashcard': updatedFlashcard, 'shouldDelete': shouldDelete};
  }

  /// Check if a flashcard should be auto-deleted based on review count
  static bool shouldAutoDelete(Flashcard flashcard) {
    return flashcard.reviewCount >= maxReviewsBeforeAutoDelete;
  }

  /// Lấy flashcards đến hạn ôn tập
  static List<Flashcard> getDueFlashcards(List<Flashcard> allFlashcards) {
    final now = DateTime.now();
    return allFlashcards.where((card) {
      // Card đến hạn nếu:
      // 1. Status là due
      if (card.status != FlashcardStatus.due) return false;

      // 2. Kiểm tra dueAt hoặc nextReviewDate
      // Nếu có dueAt, kiểm tra dueAt <= now
      if (card.dueAt != null) {
        final dueAt = card.dueAt!;
        // Đến hạn nếu dueAt <= now (trong vòng 1 giờ để tránh lỗi timezone)
        final diff = dueAt.difference(now);
        if (diff.inSeconds <= 0) {
          return true;
        }
        // Nếu dueAt trong quá khứ hoặc hiện tại, coi như đến hạn
        if (dueAt.isBefore(now) || dueAt.isAtSameMomentAs(now)) {
          return true;
        }
      }

      // Nếu không có dueAt, kiểm tra nextReviewDate
      if (card.nextReviewDate != null) {
        final nextReview = card.nextReviewDate!;
        final diff = nextReview.difference(now);
        if (diff.inSeconds <= 0) {
          return true;
        }
        if (nextReview.isBefore(now) || nextReview.isAtSameMomentAs(now)) {
          return true;
        }
      }

      // Nếu cả dueAt và nextReviewDate đều null, coi như đến hạn (flashcard mới)
      if (card.dueAt == null && card.nextReviewDate == null) {
        return true;
      }

      return false;
    }).toList();
  }

  /// Tính số flashcards đến hạn
  static int countDueFlashcards(List<Flashcard> allFlashcards) {
    return getDueFlashcards(allFlashcards).length;
  }
}

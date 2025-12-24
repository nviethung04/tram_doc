import 'package:flutter/material.dart';
import '../../data/services/flashcard_service.dart';
import '../../models/flashcard.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FlashcardSessionScreen extends StatefulWidget {
  const FlashcardSessionScreen({super.key});

  @override
  State<FlashcardSessionScreen> createState() => _FlashcardSessionScreenState();
}

class _FlashcardSessionScreenState extends State<FlashcardSessionScreen> {
  final FlashcardService _flashcardService = FlashcardService();
  List<Flashcard> _flashcards = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDueFlashcards();
  }

  Future<void> _loadDueFlashcards() async {
    try {
      setState(() => _loading = true);
      final flashcards = await _flashcardService.getDueFlashcards();
      setState(() {
        _flashcards = flashcards;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _showAnswerToggle() {
    setState(() => _showAnswer = !_showAnswer);
  }

  Future<void> _handleReview(int quality) async {
    if (_currentIndex >= _flashcards.length) return;

    final flashcard = _flashcards[_currentIndex];
    try {
      await _flashcardService.markAsReviewed(
        flashcardId: flashcard.id,
        quality: quality,
      );

      // Chuyển sang flashcard tiếp theo
      if (_currentIndex < _flashcards.length - 1) {
        setState(() {
          _currentIndex++;
          _showAnswer = false;
        });
      } else {
        // Đã xong tất cả flashcards
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã hoàn thành ôn tập!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Ôn tập Flashcard'),
          backgroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_flashcards.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Ôn tập Flashcard'),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
              const SizedBox(height: 16),
              Text(
                'Không có flashcard nào cần ôn tập',
                style: AppTypography.heading3,
              ),
              const SizedBox(height: 8),
              Text(
                'Tất cả flashcards đã được ôn tập',
                style: AppTypography.body.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final flashcard = _flashcards[_currentIndex];
    final progress = (_currentIndex + 1) / _flashcards.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Ôn tập (${_currentIndex + 1}/${_flashcards.length})'),
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _showAnswerToggle,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_showAnswer) ...[
                            Text(
                              'Câu hỏi',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              flashcard.question,
                              style: AppTypography.heading2,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Chạm để xem đáp án',
                              style: AppTypography.body.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Đáp án',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              flashcard.answer,
                              style: AppTypography.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_showAnswer) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Bạn nhớ được bao nhiêu?',
                      style: AppTypography.bodyBold,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ReviewButton(
                            label: 'Quên',
                            color: AppColors.error,
                            icon: Icons.close,
                            onPressed: () => _handleReview(0), // again
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ReviewButton(
                            label: 'Khó',
                            color: Colors.orange,
                            icon: Icons.help_outline,
                            onPressed: () => _handleReview(1), // hard
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ReviewButton(
                            label: 'Tốt',
                            color: AppColors.primary,
                            icon: Icons.check,
                            onPressed: () => _handleReview(2), // good
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ReviewButton(
                            label: 'Dễ',
                            color: AppColors.success,
                            icon: Icons.star,
                            onPressed: () => _handleReview(3), // easy
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _ReviewButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

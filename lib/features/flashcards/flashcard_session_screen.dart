import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../data/services/flashcard_service.dart';
import '../../models/flashcard.dart';
import 'review_summary_screen.dart';

class FlashcardSessionScreen extends StatefulWidget {
  final List<Flashcard> cards;
  const FlashcardSessionScreen({super.key, required this.cards});

  @override
  State<FlashcardSessionScreen> createState() => _FlashcardSessionScreenState();
}

class _FlashcardSessionScreenState extends State<FlashcardSessionScreen> {
  final _flashcardService = FlashcardService();
  int index = 0;
  bool showAnswer = false;
  bool isProcessing = false;
  int remember = 0;
  int medium = 0;
  int hard = 0;

  Flashcard get card => widget.cards[index];

  Future<void> _markAndNext(String difficulty) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      // Cập nhật thống kê
      if (difficulty == 'easy') {
        remember++;
      } else if (difficulty == 'medium') {
        medium++;
      } else {
        hard++;
      }

      // Lưu kết quả lên Firestore
      await _flashcardService.markAsReviewed(
        flashcardId: card.id,
        difficulty: difficulty,
      );

      if (mounted) {
        _next();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  void _next() {
    if (index == widget.cards.length - 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReviewSummaryScreen(
            total: widget.cards.length,
            remembered: remember,
            forgotten: hard,
          ),
        ),
      );
      return;
    }
    setState(() {
      index++;
      showAnswer = false;
      isProcessing = false;
    });
  }

  Future<void> _markAsLater() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      await _flashcardService.markAsLater(card.id);
      if (mounted) {
        _next();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ôn tập')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}/${widget.cards.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.question,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  if (showAnswer)
                    Text(
                      card.answer,
                      style: Theme.of(context).textTheme.bodyLarge,
                    )
                  else
                    PrimaryButton(
                      label: 'Hiện đáp án',
                      onPressed: () => setState(() => showAnswer = true),
                    ),
                ],
              ),
            ),
            const Spacer(),
            if (showAnswer)
              isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        PrimaryButton(
                          label: 'Dễ (7 ngày)',
                          onPressed: () => _markAndNext('easy'),
                        ),
                        const SizedBox(height: 8),
                        SecondaryButton(
                          label: 'Trung bình (3 ngày)',
                          onPressed: () => _markAndNext('medium'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _markAndNext('hard'),
                          child: const Text('Khó (1 ngày)'),
                        ),
                      ],
                    ),
            TextButton(
              onPressed: isProcessing ? null : _markAsLater,
              child: const Text('Ôn lần sau'),
            ),
          ],
        ),
      ),
    );
  }
}

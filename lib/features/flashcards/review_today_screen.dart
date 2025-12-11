import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../data/mock_data.dart';
import '../../models/flashcard.dart';
import 'flashcard_session_screen.dart';

class ReviewTodayScreen extends StatelessWidget {
  const ReviewTodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dueCount = flashcards.where((f) => f.status == FlashcardStatus.due).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Ôn tập hôm nay')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hôm nay bạn có $dueCount ý tưởng cần ôn lại.', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Chỉ mất khoảng 2 phút.'),
            const Spacer(),
            PrimaryButton(
              label: 'Bắt đầu ôn',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FlashcardSessionScreen(
                      cards: flashcards.where((f) => f.status == FlashcardStatus.due).toList(),
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

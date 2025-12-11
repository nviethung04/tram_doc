import 'package:flutter/material.dart';
import '../../components/primary_app_bar.dart';
import '../../components/app_chip.dart';
import '../../data/mock_data.dart';
import '../../models/flashcard.dart';
import 'flashcard_session_screen.dart';
import 'review_today_screen.dart';

class FlashcardOverviewScreen extends StatefulWidget {
  const FlashcardOverviewScreen({super.key});

  @override
  State<FlashcardOverviewScreen> createState() => _FlashcardOverviewScreenState();
}

class _FlashcardOverviewScreenState extends State<FlashcardOverviewScreen> {
  FlashcardStatus? status;

  @override
  Widget build(BuildContext context) {
    final filtered = status == null ? flashcards : flashcards.where((f) => f.status == status).toList();
    return Scaffold(
      appBar: const PrimaryAppBar(title: 'Flashcards', showBack: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AppChip(
                  label: 'Tất cả',
                  selected: status == null,
                  onTap: () => setState(() => status = null),
                ),
                const SizedBox(width: 8),
                AppChip(
                  label: 'Ôn hôm nay',
                  selected: status == FlashcardStatus.due,
                  onTap: () => setState(() => status = FlashcardStatus.due),
                ),
                const SizedBox(width: 8),
                AppChip(
                  label: 'Chờ lần sau',
                  selected: status == FlashcardStatus.later,
                  onTap: () => setState(() => status = FlashcardStatus.later),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final card = filtered[i];
                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text(card.question),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(card.bookTitle),
                      Text('Đã ôn ${card.timesReviewed} lần · ${card.level}'),
                    ],
                  ),
                  trailing: Text(
                    card.status == FlashcardStatus.due ? 'Ôn hôm nay' : (card.status == FlashcardStatus.done ? 'Đã xong' : 'Chờ'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => FlashcardSessionScreen(cards: filtered)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReviewTodayScreen()));
        },
        label: const Text('Ôn tập hôm nay'),
        icon: const Icon(Icons.play_arrow),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../data/services/flashcard_service.dart';
import '../../data/services/spaced_repetition_service.dart';
import '../../models/flashcard.dart';
import 'flashcard_session_screen.dart';

class ReviewTodayScreen extends StatefulWidget {
  const ReviewTodayScreen({super.key});

  @override
  State<ReviewTodayScreen> createState() => _ReviewTodayScreenState();
}

class _ReviewTodayScreenState extends State<ReviewTodayScreen> {
  final _flashcardService = FlashcardService();
  List<Flashcard> _dueCards = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Don't call _loadDueFlashcards() here anymore, stream will handle it
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ôn tập hôm nay')),
      body: StreamBuilder<List<Flashcard>>(
        stream: _flashcardService.streamFlashcards(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Filter due flashcards in real-time
          final allCards = snapshot.data ?? [];
          final dueCards = SpacedRepetitionService.getDueFlashcards(allCards);

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dueCards.isEmpty
                      ? 'Tuyệt vời! Bạn đã hoàn thành hết flashcard hôm nay.'
                      : 'Hôm nay bạn có ${dueCards.length} flashcard cần ôn lại.',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  dueCards.isEmpty
                      ? 'Hãy nghỉ ngơi hoặc tạo thêm flashcard mới.'
                      : 'Chỉ mất khoảng ${(dueCards.length * 0.5).ceil()} phút.',
                ),
                if (dueCards.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Danh sách flashcard',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.builder(
                                itemCount: dueCards.length,
                                itemBuilder: (context, index) {
                                  final card = dueCards[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(
                                        card.question,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(card.bookTitle),
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                      onTap: () async {
                                        // Practice single card
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => FlashcardSessionScreen(
                                              cards: [card],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Spacer(),
                if (dueCards.isNotEmpty)
                  PrimaryButton(
                    label: 'Bắt đầu ôn tất cả',
                    onPressed: () async {
                      if (!mounted) return;
                      final navigator = Navigator.of(context);
                      final result = await navigator.push(
                        MaterialPageRoute(
                          builder: (_) =>
                              FlashcardSessionScreen(cards: dueCards),
                        ),
                      );
                      if (result == true && mounted) {
                        navigator.pop(true);
                      }
                    },
                  )
                else
                  PrimaryButton(
                    label: 'Quay lại',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../models/flashcard.dart';
import 'review_summary_screen.dart';

class FlashcardSessionScreen extends StatefulWidget {
  final List<Flashcard> cards;
  const FlashcardSessionScreen({super.key, required this.cards});

  @override
  State<FlashcardSessionScreen> createState() => _FlashcardSessionScreenState();
}

class _FlashcardSessionScreenState extends State<FlashcardSessionScreen> {
  int index = 0;
  bool showAnswer = false;
  int remember = 0;
  int hard = 0;

  Flashcard get card => widget.cards[index];

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
    });
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
            Text('${index + 1}/${widget.cards.length}', style: Theme.of(context).textTheme.bodySmall),
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
                  Text(card.question, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  if (showAnswer)
                    Text(card.answer, style: Theme.of(context).textTheme.bodyLarge)
                  else
                    PrimaryButton(label: 'Hiện đáp án', onPressed: () => setState(() => showAnswer = true)),
                ],
              ),
            ),
            const Spacer(),
            if (showAnswer)
              Column(
                children: [
                  PrimaryButton(
                    label: 'Nhớ rõ',
                    onPressed: () {
                      remember++;
                      _next();
                    },
                  ),
                  const SizedBox(height: 8),
                  SecondaryButton(
                    label: 'Lấp lóe',
                    onPressed: () => _next(),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      hard++;
                      _next();
                    },
                    child: const Text('Quên'),
                  ),
                ],
              ),
            TextButton(onPressed: _next, child: const Text('Bỏ qua Flashcard này')),
          ],
        ),
      ),
    );
  }
}

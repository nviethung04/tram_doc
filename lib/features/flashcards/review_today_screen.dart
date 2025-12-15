import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../data/services/flashcard_service.dart';
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
    _loadDueFlashcards();
  }

  Future<void> _loadDueFlashcards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cards = await _flashcardService.getDueFlashcards();
      if (mounted) {
        setState(() {
          _dueCards = cards;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ôn tập hôm nay')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
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
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadDueFlashcards,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dueCards.isEmpty
                        ? 'Tuyệt vời! Bạn đã hoàn thành hết flashcard hôm nay.'
                        : 'Hôm nay bạn có ${_dueCards.length} flashcard cần ôn lại.',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _dueCards.isEmpty
                        ? 'Hãy nghỉ ngơi hoặc tạo thêm flashcard mới.'
                        : 'Chỉ mất khoảng ${(_dueCards.length * 0.5).ceil()} phút.',
                  ),
                  const Spacer(),
                  if (_dueCards.isNotEmpty)
                    PrimaryButton(
                      label: 'Bắt đầu ôn',
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                FlashcardSessionScreen(cards: _dueCards),
                          ),
                        );
                        if (result == true && mounted) {
                          Navigator.of(context).pop(true);
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
            ),
    );
  }
}

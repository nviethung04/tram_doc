import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../data/services/notes_service.dart';
import '../../models/book.dart';
import '../../models/note.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class KeyIdeasScreen extends StatefulWidget {
  final Book book;

  const KeyIdeasScreen({super.key, required this.book});

  @override
  State<KeyIdeasScreen> createState() => _KeyIdeasScreenState();
}

class _KeyIdeasScreenState extends State<KeyIdeasScreen> {
  final _notesService = NotesService();
  List<Note> _keyIdeas = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadKeyIdeas();
  }

  Future<void> _loadKeyIdeas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ideas = await _notesService.getKeyIdeasByBook(widget.book.id);
      if (mounted) {
        setState(() {
          _keyIdeas = ideas;
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
      appBar: AppBar(title: const Text('Tổng hợp Ý chính')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _ErrorState(message: _errorMessage!, onRetry: _loadKeyIdeas)
          : _keyIdeas.isEmpty
          ? _EmptyState(bookTitle: widget.book.title)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.book.title, style: AppTypography.h2),
                              const SizedBox(height: 4),
                              Text(
                                '${_keyIdeas.length} ý chính quan trọng',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('Những ý chính từ cuốn sách', style: AppTypography.h2),
                  const SizedBox(height: 16),

                  // Key ideas list
                  ..._keyIdeas.asMap().entries.map((entry) {
                    final index = entry.key;
                    final idea = entry.value;
                    return _KeyIdeaCard(number: index + 1, idea: idea);
                  }),

                  const SizedBox(height: 32),

                  // Generate flashcards button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              'Tạo Flashcards',
                              style: AppTypography.bodyBold,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tự động tạo flashcards từ ${keyIdeas.length} ý chính này để ôn tập hiệu quả hơn.',
                          style: AppTypography.body,
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Tạo Flashcards ngay',
                          onPressed: () =>
                              _generateFlashcards(context, keyIdeas),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _generateFlashcards(BuildContext context, List<Note> keyIdeas) {
    // TODO: Implement flashcard generation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sẽ tạo ${keyIdeas.length} flashcards từ ý chính'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _KeyIdeaCard extends StatelessWidget {
  final int number;
  final Note idea;

  const _KeyIdeaCard({required this.number, required this.idea});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(idea.content, style: AppTypography.body),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (idea.page != null) ...[
                      Icon(Icons.menu_book, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('Trang ${idea.page}', style: AppTypography.caption),
                    ],
                    if (idea.isFlashcard) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.credit_card,
                        size: 14,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Đã tạo flashcard',
                        style: AppTypography.caption.copyWith(
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.star, color: Colors.amber, size: 24),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Lỗi tải dữ liệu',
              style: AppTypography.h2.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.body.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Thử lại', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String bookTitle;

  const _EmptyState({required this.bookTitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có Ý chính nào',
              style: AppTypography.h2.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Đánh dấu những ghi chú quan trọng nhất làm "Ý chính" để tạo flashcards hiệu quả hơn.',
              style: AppTypography.body.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../data/services/notes_service.dart';
import '../../data/services/flashcard_service.dart';
import '../../data/mock_data.dart';
import '../../models/note.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'create_note_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final _notesService = NotesService();
  final _flashcardService = FlashcardService();
  late Note _currentNote;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
  }

  @override
  Widget build(BuildContext context) {
    // Find book from mock data
    final book = books.firstWhere((b) => b.id == _currentNote.bookId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết ghi chú'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading ? null : () => _navigateToEdit(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.book, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentNote.bookTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(book.author, style: AppTypography.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Badges row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_currentNote.page != null)
                        _Badge(
                          icon: Icons.menu_book,
                          label: 'Trang ${_currentNote.page}',
                          color: AppColors.primary,
                        ),
                      if (_currentNote.isKeyIdea)
                        const _Badge(
                          icon: Icons.star,
                          label: 'Ý chính',
                          color: Colors.amber,
                        ),
                      if (_currentNote.isFlashcard)
                        const _Badge(
                          icon: Icons.credit_card,
                          label: 'Đã tạo Flashcard',
                          color: Colors.green,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Content
                  Text('Nội dung', style: AppTypography.h2),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _currentNote.content,
                      style: AppTypography.body.copyWith(height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Timestamps
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tạo: ${_formatDateTime(_currentNote.createdAt)}',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                        if (_currentNote.createdAt !=
                            _currentNote.updatedAt) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.update,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cập nhật: ${_formatDateTime(_currentNote.updatedAt)}',
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action button
                  if (!_currentNote.isFlashcard)
                    PrimaryButton(
                      label: 'Tạo Flashcard từ ghi chú này',
                      onPressed: () => _createFlashcard(context),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _navigateToEdit(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateNoteScreen(
          book: books.firstWhere((b) => b.id == _currentNote.bookId),
          noteToEdit: _currentNote,
        ),
      ),
    );

    // Reload note if edited
    if (result == true) {
      await _reloadNote();
    }
  }

  Future<void> _reloadNote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedNote = await _notesService.getNoteById(_currentNote.id);
      if (mounted) {
        setState(() {
          _currentNote = updatedNote;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải lại: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createFlashcard(BuildContext context) async {
    // Hiển thị dialog để nhập câu hỏi và câu trả lời
    final questionController = TextEditingController();
    final answerController = TextEditingController(text: _currentNote.content);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo Flashcard'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Câu hỏi',
                  hintText: 'Nhập câu hỏi cho flashcard...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(
                  labelText: 'Câu trả lời',
                  hintText: 'Nhập câu trả lời...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (questionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập câu hỏi')),
                );
                return;
              }
              if (answerController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập câu trả lời')),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _flashcardService.createFlashcardFromNote(
          noteId: _currentNote.id,
          bookId: _currentNote.bookId,
          bookTitle: _currentNote.bookTitle,
          question: questionController.text.trim(),
          answer: answerController.text.trim(),
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã tạo Flashcard thành công'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload note để cập nhật isFlashcard flag nếu cần
          await _reloadNote();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    questionController.dispose();
    answerController.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

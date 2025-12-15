import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../components/app_input.dart';
import '../../data/services/notes_service.dart';
import '../../models/book.dart';
import '../../models/note.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class CreateNoteScreen extends StatefulWidget {
  final Book book;
  final Note? noteToEdit;

  const CreateNoteScreen({super.key, required this.book, this.noteToEdit});

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final _contentController = TextEditingController();
  final _pageController = TextEditingController();
  final _notesService = NotesService();
  bool _isKeyIdea = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.noteToEdit != null) {
      _contentController.text = widget.noteToEdit!.content;
      _pageController.text = widget.noteToEdit!.page?.toString() ?? '';
      _isKeyIdea = widget.noteToEdit!.isKeyIdea;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    // Validation
    if (_contentController.text.trim().isEmpty) {
      _showError('Nội dung ghi chú không được để trống');
      return;
    }

    final int? pageNumber = _pageController.text.isEmpty
        ? null
        : int.tryParse(_pageController.text);

    if (_pageController.text.isNotEmpty && pageNumber == null) {
      _showError('Số trang không hợp lệ');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.noteToEdit != null) {
        // Edit existing note
        final updatedNote = widget.noteToEdit!.copyWith(
          content: _contentController.text.trim(),
          page: pageNumber,
          isKeyIdea: _isKeyIdea,
          updatedAt: DateTime.now(),
        );
        await _notesService.updateNote(widget.noteToEdit!.id, updatedNote);
      } else {
        // Create new note
        final newNote = Note(
          id: '', // Will be assigned by Firestore
          userId: '', // Will be set by NotesService with current user
          bookId: widget.book.id,
          bookTitle: widget.book.title,
          content: _contentController.text.trim(),
          page: pageNumber,
          isKeyIdea: _isKeyIdea,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _notesService.createNote(newNote);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to signal reload
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.noteToEdit != null
                  ? 'Đã cập nhật ghi chú'
                  : 'Đã thêm ghi chú mới',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Lỗi: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteNote() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa ghi chú này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog

              setState(() {
                _isLoading = true;
              });

              try {
                await _notesService.deleteNote(widget.noteToEdit!.id);

                if (mounted) {
                  Navigator.of(
                    context,
                  ).pop(true); // Return true to signal reload
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa ghi chú'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  _showError('Lỗi khi xóa: ${e.toString()}');
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.noteToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa ghi chú' : 'Thêm ghi chú mới'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteNote,
            ),
        ],
      ),
      body: SingleChildScrollView(
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
                          widget.book.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(widget.book.author, style: AppTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Page number input
            LabeledInput(
              label: 'Số trang (tùy chọn)',
              hint: 'Ví dụ: 45',
              controller: _pageController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Content input
            Text('Nội dung ghi chú', style: AppTypography.bodyBold),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Nhập nội dung ghi chú của bạn...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Key Idea toggle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đánh dấu là Ý chính',
                          style: AppTypography.bodyBold,
                        ),
                        Text(
                          'Những ý quan trọng nhất từ cuốn sách',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isKeyIdea,
                    onChanged: (value) => setState(() => _isKeyIdea = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    label: isEditing ? 'Cập nhật' : 'Lưu ghi chú',
                    onPressed: _saveNote,
                  ),
          ],
        ),
      ),
    );
  }
}

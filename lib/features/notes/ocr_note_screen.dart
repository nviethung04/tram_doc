import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../components/app_button.dart';
import '../../data/services/notes_service.dart';
import '../../models/book.dart';
import '../../models/note.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class OCRNoteScreen extends StatefulWidget {
  final Book book;

  const OCRNoteScreen({super.key, required this.book});

  @override
  State<OCRNoteScreen> createState() => _OCRNoteScreenState();
}

class _OCRNoteScreenState extends State<OCRNoteScreen> {
  final _notesService = NotesService();
  final _textController = TextEditingController();
  final _pageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  Uint8List? _imageBytes;
  bool _isProcessing = false;
  bool _isOcrProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _textController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _errorMessage = null;
        });

        // Đọc bytes của ảnh
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });

        // Tự động chạy OCR
        await _performOCR();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi chọn ảnh: ${e.toString()}';
      });
    }
  }

  Future<void> _performOCR() async {
    if (_imageBytes == null) return;

    setState(() {
      _isOcrProcessing = true;
      _errorMessage = null;
    });

    try {
      // Tạo note từ ảnh với OCR
      final note = await _notesService.createNoteFromImage(
        bookId: widget.book.id,
        bookTitle: widget.book.title,
        imageBytes: _imageBytes!,
        page: _pageController.text.isNotEmpty
            ? int.tryParse(_pageController.text)
            : null,
      );

      if (mounted) {
        setState(() {
          _textController.text = note.content;
          _isOcrProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã nhận dạng văn bản thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOcrProcessing = false;
          _errorMessage = 'Lỗi OCR: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi nhận dạng văn bản: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveNote() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập hoặc nhận dạng văn bản'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Nếu đã có ảnh, note đã được tạo trong _performOCR
      // Chỉ cần cập nhật content nếu user đã chỉnh sửa
      if (_imageBytes != null) {
        // Note đã được tạo, chỉ cần thông báo thành công
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã lưu ghi chú thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Nếu không có ảnh, tạo note thủ công từ text
        final newNote = Note(
          id: '',
          userId: '',
          bookId: widget.book.id,
          bookTitle: widget.book.title,
          content: _textController.text.trim(),
          page: _pageController.text.isNotEmpty
              ? int.tryParse(_pageController.text)
              : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _notesService.createNote(newNote);

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã lưu ghi chú thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Lỗi khi lưu: ${e.toString()}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chụp ảnh ghi chú (OCR)'),
        actions: [
          if (_isOcrProcessing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Book info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
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
                          style: AppTypography.bodyBold,
                        ),
                        if (widget.book.author.isNotEmpty)
                          Text(
                            widget.book.author,
                            style: AppTypography.caption.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Image picker section
            if (_selectedImage == null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có ảnh',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Chụp ảnh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Chọn ảnh'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Stack(
                children: [
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          color: Colors.white,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                          onPressed: () => _performOCR(),
                          tooltip: 'Nhận dạng lại',
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          color: Colors.white,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                              _imageBytes = null;
                              _textController.clear();
                            });
                          },
                          tooltip: 'Xóa ảnh',
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Page input
            TextField(
              controller: _pageController,
              decoration: const InputDecoration(
                labelText: 'Trang (tùy chọn)',
                hintText: 'Nhập số trang',
                prefixIcon: Icon(Icons.bookmark),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // OCR result text field
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Kết quả nhận dạng văn bản',
                hintText: 'Văn bản sẽ hiện ở đây sau khi nhận dạng...',
                prefixIcon: const Icon(Icons.text_fields),
                border: const OutlineInputBorder(),
                suffixIcon: _isOcrProcessing
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              minLines: 6,
              maxLines: 12,
              enabled: !_isOcrProcessing,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            PrimaryButton(
              label: _isOcrProcessing
                  ? 'Đang nhận dạng...'
                  : _imageBytes == null
                      ? 'Lưu ghi chú'
                      : 'Lưu ghi chú & tạo Flashcard',
              onPressed: _isProcessing || _isOcrProcessing ? null : _saveNote,
            ),

            const SizedBox(height: 12),

            if (_imageBytes != null && _textController.text.isNotEmpty)
              OutlinedButton.icon(
                onPressed: _isProcessing || _isOcrProcessing
                    ? null
                    : () {
                        // Navigate to create flashcard screen
                        // TODO: Implement flashcard creation from OCR text
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tính năng tạo flashcard từ OCR sẽ được thêm sau'),
                          ),
                        );
                      },
                icon: const Icon(Icons.credit_card),
                label: const Text('Tạo Flashcard từ văn bản này'),
              ),
          ],
        ),
      ),
    );
  }
}

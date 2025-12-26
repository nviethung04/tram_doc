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
  bool _ocrCompleted = false;

  String? _errorMessage;
  String? _createdNoteId; // Lưu note ID sau khi OCR để có thể cập nhật sau

  // OCR Language selection
  String _ocrLanguage = 'vnm';
  final Map<String, String> _languageLabels = const {
    'vnm': 'Tiếng Việt',
    'eng': 'English',
    'jpn': '日本語',
    'kor': '한국어',
    'chi_sim': '中文(简体)',
    'chi_tra': '中文(繁體)',
  };

  @override
  void dispose() {
    _textController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /* ================= IMAGE PICK ================= */

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      setState(() {
        _selectedImage = File(image.path);
        _imageBytes = bytes;
        _errorMessage = null;
        _ocrCompleted = false;
        _textController.clear();
      });

      await _performOCR();
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi chọn ảnh: $e';
      });
    }
  }

  /* ================= LANGUAGE PICK ================= */

  Future<void> _pickOcrLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _languageLabels.entries.map((e) {
              return RadioListTile<String>(
                value: e.key,
                groupValue: _ocrLanguage,
                title: Text(e.value),
                onChanged: (val) => Navigator.pop(context, val),
              );
            }).toList(),
          ),
        );
      },
    );

    if (selected == null || selected == _ocrLanguage) return;

    setState(() {
      _ocrLanguage = selected;
      _ocrCompleted = false;
    });

    // Nếu đã có ảnh, hỏi có OCR lại luôn không
    if (_imageBytes != null) {
      final rerun = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('OCR lại với ngôn ngữ mới?'),
          content: Text(
            'Bạn vừa chọn: ${_languageLabels[_ocrLanguage]}. Chạy OCR lại ngay?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Để sau'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OCR lại'),
            ),
          ],
        ),
      );

      if (rerun == true) {
        await _performOCR();
      }
    }
  }

  /* ================= OCR ================= */

  Future<void> _performOCR() async {
    if (_imageBytes == null) return;

    if (_textController.text.isNotEmpty) {
      final overwrite = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Nhận dạng lại?'),
          content: const Text(
            'Văn bản hiện tại sẽ bị ghi đè. Bạn có chắc chắn muốn tiếp tục?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tiếp tục'),
            ),
          ],
        ),
      );

      if (overwrite != true) return;
    }

    setState(() {
      _isOcrProcessing = true;
      _errorMessage = null;
    });

    try {
      final note = await _notesService.createNoteFromImage(
        bookId: widget.book.id,
        bookTitle: widget.book.title,
        imageBytes: _imageBytes!,
        page: _pageController.text.isNotEmpty
            ? int.tryParse(_pageController.text)
            : null,
        language: _ocrLanguage,
      );

      if (!mounted) return;

      setState(() {
        _textController.text = note.content;
        _ocrCompleted = true;
        _isOcrProcessing = false;
        _createdNoteId = note.id; // Lưu note ID để có thể cập nhật sau
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã nhận dạng xong – bạn có thể chỉnh sửa văn bản'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isOcrProcessing = false;
        _errorMessage = 'Lỗi OCR: $e';
      });
    }
  }

  /* ================= SAVE ================= */

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

    setState(() => _isProcessing = true);

    try {
      // Nếu đã có note ID (đã OCR), cập nhật note đó
      if (_createdNoteId != null) {
        final existingNote = await _notesService.getNoteById(_createdNoteId!);
        final updatedNote = existingNote.copyWith(
          content: _textController.text.trim(),
          page: _pageController.text.isNotEmpty
              ? int.tryParse(_pageController.text)
              : null,
        );
        await _notesService.updateNote(_createdNoteId!, updatedNote);
      } else if (_imageBytes == null) {
        // Tạo note mới nếu chưa có ảnh (nhập tay)
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
      }
      // Nếu có _imageBytes nhưng chưa OCR (chưa có _createdNoteId),
      // thì note sẽ được tạo trong _performOCR, không cần làm gì ở đây

      if (!mounted) return;

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu ghi chú thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Lỗi khi lưu: $e';
      });
    }
  }

  /* ================= UI ================= */

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
          mainAxisSize: MainAxisSize.min,
          children: [
            /* ===== BOOK INFO ===== */
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
                        Text(widget.book.title, style: AppTypography.bodyBold),
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

            /* ===== IMAGE PICK ===== */
            if (_selectedImage == null)
              _buildPickImage()
            else
              _buildImagePreview(),

            const SizedBox(height: 16),

            /* ===== PAGE ===== */
            TextField(
              controller: _pageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Trang (tùy chọn)',
                prefixIcon: Icon(Icons.bookmark),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /* ===== OCR LANGUAGE ===== */
            OutlinedButton.icon(
              onPressed: _isOcrProcessing ? null : _pickOcrLanguage,
              icon: const Icon(Icons.translate),
              label: Text(
                'Ngôn ngữ OCR: ${_languageLabels[_ocrLanguage] ?? _ocrLanguage}',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 16),

            /* ===== OCR STATUS ===== */
            if (_ocrCompleted)
              const Text(
                '✓ Đã nhận dạng xong, bạn có thể chỉnh sửa văn bản',
                style: TextStyle(color: Colors.green),
              ),

            const SizedBox(height: 8),

            /* ===== TEXT ===== */
            TextField(
              controller: _textController,
              minLines: 6,
              maxLines: 12,
              enabled: !_isOcrProcessing,
              decoration: const InputDecoration(
                labelText: 'Nội dung ghi chú',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.text_fields),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                            _imageBytes = null;
                          });
                        },
                        child: const Text('Nhập tay'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            /* ===== SAVE ===== */
            PrimaryButton(
              label: _isOcrProcessing ? 'Đang nhận dạng...' : 'Lưu ghi chú',
              onPressed: _isProcessing || _isOcrProcessing ? null : _saveNote,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickImage() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Chụp ảnh'),
              ),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Chọn ảnh'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        Container(
          height: 300,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_selectedImage!, fit: BoxFit.contain),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.refresh),
            color: Colors.white,
            onPressed: _performOCR,
          ),
        ),
      ],
    );
  }
}

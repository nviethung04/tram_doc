import 'package:flutter/material.dart';
import '../../components/app_input.dart';
import '../../components/app_button.dart';
import '../../theme/app_typography.dart';
import 'note_ocr_screen.dart';

class NoteEditScreen extends StatelessWidget {
  final String? bookId;
  final String? bookTitle;
  const NoteEditScreen({super.key, this.bookId, this.bookTitle});

  @override
  Widget build(BuildContext context) {
    final bookController = TextEditingController(text: bookTitle ?? '');
    final pageController = TextEditingController();
    final contentController = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Ghi chú mới')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tạo ghi chú nhanh', style: AppTypography.h2),
            const SizedBox(height: 16),
            LabeledInput(label: 'Chọn sách', hint: 'Nhập tên sách', controller: bookController),
            const SizedBox(height: 12),
            LabeledInput(label: 'Trang', hint: 'vd: 150', controller: pageController, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            const Text('Nội dung', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: contentController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(hintText: 'Nhập ý chính...'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(value: true, onChanged: (_) {}),
                const Text('Chuyển thành Flashcard'),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Lưu ghi chú', onPressed: () {}),
            const SizedBox(height: 16),
            SecondaryButton(
              label: 'Chụp đoạn sách (OCR)',
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NoteOcrScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../components/app_button.dart';

class NoteOcrScreen extends StatelessWidget {
  const NoteOcrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController(
      text: 'Văn bản OCR sẽ hiện ở đây để chỉnh sửa...',
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Chụp đoạn sách (OCR)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: Text('Camera preview placeholder')),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Chụp', onPressed: () {}),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: TextButton(onPressed: () {}, child: const Text('Nhập text thủ công')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Kết quả OCR'),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Trang'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Lưu ghi chú & tạo Flashcard', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../components/app_button.dart';

class NoteOcrScreen extends StatefulWidget {
  const NoteOcrScreen({super.key});

  @override
  State<NoteOcrScreen> createState() => _NoteOcrScreenState();
}

class _NoteOcrScreenState extends State<NoteOcrScreen> {
  late final TextEditingController _textController;
  final TextEditingController _pageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: 'Văn bản OCR sẽ hiện ở đây để chỉnh sửa...',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              controller: _textController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Kết quả OCR'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pageController,
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

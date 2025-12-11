import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../theme/app_typography.dart';

class KeyIdeasScreen extends StatelessWidget {
  final String bookTitle;
  const KeyIdeasScreen({super.key, required this.bookTitle});

  @override
  Widget build(BuildContext context) {
    final controllers = List.generate(5, (_) => TextEditingController());
    return Scaffold(
      appBar: AppBar(title: Text('Ý tưởng chính')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ý tưởng chính từ $bookTitle', style: AppTypography.h2),
            const SizedBox(height: 8),
            Text(
              'Viết 3–5 gạch đầu dòng để tóm tắt những điều quan trọng nhất.',
              style: AppTypography.body,
            ),
            const SizedBox(height: 16),
            ...List.generate(
              controllers.length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: controllers[i],
                  decoration: InputDecoration(
                    prefixText: '${i + 1}. ',
                    hintText: 'Ý tưởng ${i + 1}',
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Checkbox(value: true, onChanged: (_) {}),
                const Text('Tự động tạo flashcard từ các ý tưởng này'),
              ],
            ),
            const Spacer(),
            PrimaryButton(label: 'Lưu', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

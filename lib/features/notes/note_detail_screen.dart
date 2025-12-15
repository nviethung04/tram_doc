import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../components/app_button.dart';
import '../../theme/app_colors.dart';

class NoteDetailScreen extends StatelessWidget {
  final Note note;
  const NoteDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(note.bookTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text('Trang ${note.page ?? "-"}'),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(note.isFlashcard ? 'Đã tạo Flashcard' : 'Chưa tạo'),
                  backgroundColor: AppColors.accent.withOpacity(0.12),
                ),
              ],
            ),
            const Spacer(),
            PrimaryButton(label: 'Sửa ghi chú', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../components/primary_app_bar.dart';
import '../../components/empty_state.dart';
import '../../data/mock_data.dart';
import 'note_edit_screen.dart';
import 'note_detail_screen.dart';
import '../flashcards/flashcard_overview_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PrimaryAppBar(title: 'Notes & Flashcards', showSearch: true),
      body: SafeArea(
        child: notes.isEmpty
            ? const EmptyState(
                icon: Icons.note_alt_outlined,
                title: 'Chưa có ghi chú',
                description: 'Thêm ghi chú để biến ý tưởng thành flashcard.',
                actionLabel: 'Thêm ghi chú mới',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final note = notes[i];
                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: Colors.white,
                    title: Text(note.bookTitle),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          note.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text('Trang ${note.page ?? "-"} · ${note.isFlashcard ? "Đã tạo flashcard" : "Chưa tạo"}'),
                      ],
                    ),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey.shade500),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
                      );
                    },
                  );
                },
              ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'flashcards',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FlashcardOverviewScreen()),
              );
            },
            icon: const Icon(Icons.bolt_outlined),
            label: const Text('Ôn tập hôm nay'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'addNote',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NoteEditScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Thêm ghi chú'),
          ),
        ],
      ),
    );
  }
}

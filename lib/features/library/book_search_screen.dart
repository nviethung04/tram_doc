import 'package:flutter/material.dart';
import '../../components/book_card.dart';
import '../../components/primary_app_bar.dart';
import '../../data/mock_data.dart';
import '../../models/book.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';

class BookSearchScreen extends StatefulWidget {
  const BookSearchScreen({super.key});

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  String query = '';
  BookStatus? selectedShelf;

  @override
  Widget build(BuildContext context) {
    final results = books
        .where(
          (b) => b.title.toLowerCase().contains(query.toLowerCase()) ||
              b.author.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: const PrimaryAppBar(title: 'Tìm kiếm sách', showBack: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SearchBar(
                hint: 'Tìm theo tên sách, tác giả...',
                onChanged: (text) => setState(() => query = text),
                onSubmit: (_) {},
              ),
              const SizedBox(height: AppSpacing.section),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.search, color: AppColors.textMuted, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nhập tên sách hoặc tác giả để bắt đầu tìm kiếm',
                      style: AppTypography.body.copyWith(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              Expanded(
                child: ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final book = results[i];
                    return BookCard(
                      book: book,
                      onTap: () {},
                      onAdd: () => _openAddToShelf(context, book),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddToShelf(BuildContext context, Book book) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chọn kệ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              for (final status in BookStatus.values)
                RadioListTile<BookStatus>(
                  title: Text(status.label),
                  value: status,
                  groupValue: selectedShelf,
                  onChanged: (val) => setState(() => selectedShelf = val),
                ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã thêm "${book.title}" vào kệ ${selectedShelf?.label ?? ''}')),
                  );
                },
                child: const Text('Thêm'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmit;

  const _SearchBar({
    required this.hint,
    this.onChanged,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.divider),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: onChanged,
                    onSubmitted: onSubmit,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.tune, size: 18),
          label: const Text('Tìm'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

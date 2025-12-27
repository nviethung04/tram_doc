import 'dart:async';

import 'package:flutter/material.dart';

import '../../components/book_card.dart';
import '../../components/primary_app_bar.dart';
import '../../data/services/google_books_service.dart';
import '../../data/services/book_service.dart';
import '../../models/book.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookSearchScreen extends StatefulWidget {
  const BookSearchScreen({super.key});

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final _service = GoogleBooksService();
  final _bookService = BookService();
  final _auth = FirebaseAuth.instance;
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  String query = '';
  bool loading = false;
  String? error;
  List<Book> results = [];
  BookStatus? selectedShelf;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String text) {
    setState(() => query = text);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _runSearch);
  }

  Future<void> _runSearch() async {
    final text = query.trim();
    if (text.isEmpty) {
      setState(() {
        results = [];
        error = null;
      });
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await _service.searchBooks(text);
      if (!mounted) return;
      setState(() => results = data);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'Không tải được kết quả. Vui lòng thử lại.';
        results = [];
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _openAddToShelf(BuildContext context, Book book) {
    selectedShelf ??= BookStatus.wantToRead;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        BookStatus tempSelected = selectedShelf!;
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      groupValue: tempSelected,
                      onChanged: (val) {
                        if (val == null) return;
                        setModalState(() => tempSelected = val);
                        setState(() => selectedShelf = val);
                      },
                    ),
                  ElevatedButton(
                    onPressed: () async {
                      final user = _auth.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Hãy đăng nhập để lưu sách vào thư viện')),
                        );
                        return;
                      }
                      final chosen = tempSelected;
                      final added = book.copyWith(status: chosen);
                      try {
                        await _bookService.upsertBook(added);
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã thêm "${book.title}" vào kệ ${chosen.label}')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi lưu sách: $e')),
                        );
                      }
                    },
                    child: const Text('Thêm'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;

    return Scaffold(
      appBar: const PrimaryAppBar(title: 'Tìm kiếm sách', showBack: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SearchBar(
                controller: _controller,
                hint: 'Tìm theo tên sách, tác giả...',
                onChanged: _onQueryChanged,
                onSubmit: (_) => _runSearch(),
              ),
              const SizedBox(height: AppSpacing.section),
              Expanded(child: _buildResults(hasQuery)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(bool hasQuery) {
    if (!hasQuery) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      );
    }
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Text(error!, style: AppTypography.body.copyWith(color: AppColors.textMuted)),
      );
    }
    if (results.isEmpty) {
      return Center(
        child: Text('Không tìm thấy sách phù hợp', style: AppTypography.body),
      );
    }
    return ListView.separated(
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
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmit;

  const _SearchBar({
    required this.hint,
    this.controller,
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
                    controller: controller,
                    onChanged: onChanged,
                    onSubmitted: onSubmit,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () => onSubmit?.call(controller?.text ?? ''),
          icon: const Icon(Icons.search, size: 18),
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

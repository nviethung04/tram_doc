import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../components/empty_state.dart';
import '../../components/primary_app_bar.dart';
import '../../data/services/book_service.dart';
import '../../models/book.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'add_book_method_screen.dart';
import 'book_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _bookService = BookService();
  final _auth = FirebaseAuth.instance;
  BookStatus filter = BookStatus.wantToRead;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: const PrimaryAppBar(title: 'Thư viện'),
      body: SafeArea(
        child: user == null
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: EmptyState(
                  icon: Icons.lock_outline,
                  title: 'Bạn chưa đăng nhập',
                  description: 'Đăng nhập để lưu và đồng bộ thư viện của bạn.',
                  actionLabel: 'Thêm sách',
                  iconSize: 80,
                  onAction: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddBookMethodScreen()),
                  ),
                ),
              )
            : StreamBuilder<List<Book>>(
                stream: _bookService.streamAllBooks(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Khong the tai thu vien: ${snapshot.error}',
                          style: AppTypography.body.copyWith(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final allBooks = snapshot.data ?? [];
                  final list = allBooks.where((b) => b.status == filter).toList();
                  final counts = _countsByStatus(allBooks);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatusSegment(
                          current: filter,
                          counts: counts,
                          onChanged: (s) => setState(() => filter = s),
                        ),
                        const SizedBox(height: 16),
                        if (list.isEmpty)
                          Expanded(
                            child: EmptyState(
                              icon: Icons.menu_book_outlined,
                              title: 'Tủ sách của bạn đang trống',
                              description: 'Thêm những cuốn sách bạn muốn đọc để bắt đầu hành trình.',
                              actionLabel: 'Thêm sách đầu tiên',
                              iconSize: 80,
                              onAction: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const AddBookMethodScreen()),
                                );
                              },
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.separated(
                              itemCount: list.length,
                              separatorBuilder: (_, __) => const Divider(height: 24),
                              itemBuilder: (_, i) {
                                final book = list[i];
                                return Dismissible(
                                  key: ValueKey(book.id),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) async {
                                    final shouldDelete = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: const Text('Xác nhận xoá'),
                                        content: Text('Xoá sách "${book.title}"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(dialogContext).pop(false),
                                            child: const Text('Huỷ'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(dialogContext).pop(true),
                                            child: const Text('Xoá'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (shouldDelete != true) return false;
                                    final ok = await _bookService.deleteBook(book.id);
                                    if (!ok && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Không thể xoá sách')),
                                      );
                                    }
                                    return ok;
                                  },
                                  background: const SizedBox.shrink(),
                                  secondaryBackground: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  child: _BookListItem(
                                    book: book,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddBookMethodScreen()),
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(56),
            boxShadow: const [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 6,
                offset: Offset(0, 4),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 15,
                offset: Offset(0, 10),
                spreadRadius: -3,
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Map<BookStatus, int> _countsByStatus(List<Book> all) {
    return {
      BookStatus.wantToRead: all.where((b) => b.status == BookStatus.wantToRead).length,
      BookStatus.reading: all.where((b) => b.status == BookStatus.reading).length,
      BookStatus.read: all.where((b) => b.status == BookStatus.read).length,
    };
  }
}

class _StatusSegment extends StatelessWidget {
  final BookStatus current;
  final Map<BookStatus, int> counts;
  final ValueChanged<BookStatus> onChanged;

  const _StatusSegment({
    required this.current,
    required this.counts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget item(BookStatus status) {
      final selected = current == status;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onChanged(status),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16.4),
              boxShadow: selected
                  ? const [
                      BoxShadow(color: Color(0x19000000), blurRadius: 3, offset: Offset(0, 1)),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  status.label,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: selected ? Colors.white : AppColors.textBody,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '(${counts[status] ?? 0})',
                  style: AppTypography.body.copyWith(
                    color: selected ? Colors.white : const Color(0x994B5563),
                    fontSize: 12,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 52,
      padding: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.divider, width: 1.2),
      ),
      child: Row(
        children: [
          item(BookStatus.wantToRead),
          const SizedBox(width: 8),
          item(BookStatus.reading),
          const SizedBox(width: 8),
          item(BookStatus.read),
        ],
      ),
    );
  }
}

class _BookListItem extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _BookListItem({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 110,
              width: 76,
              child: Container(
                color: AppColors.primary.withValues(alpha: 0.08),
                child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                    ? Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            Icon(Icons.menu_book, color: AppColors.primary),
                      )
                    : Icon(Icons.menu_book, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: AppTypography.bodyBold.copyWith(fontSize: 18),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: AppTypography.body.copyWith(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      border: Border.all(color: const Color(0xFFFDE585)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      book.status == BookStatus.reading
                          ? 'Đang đọc'
                          : book.status == BookStatus.wantToRead
                              ? 'Muốn đọc'
                              : 'Đã đọc',
                      style: AppTypography.caption.copyWith(color: const Color(0xFFBA4C00)),
                    ),
                  ),
                  if (book.status == BookStatus.reading) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: book.progress,
                      minHeight: 6,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                    const SizedBox(height: 4),
                    Text('${book.readPages} / ${book.totalPages}', style: AppTypography.caption),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

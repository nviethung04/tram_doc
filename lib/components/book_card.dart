import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/book.dart';
import 'progress_bar.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final bool showProgress;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  const BookCard({
    super.key,
    required this.book,
    this.showProgress = false,
    this.onTap,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 64,
                height: 84,
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    book.title,
                    style: AppTypography.bodyBold,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  if (showProgress && book.status == BookStatus.reading) ...[
                    ProgressBar(value: book.progress),
                    const SizedBox(height: 6),
                    Text(
                      '${book.readPages}/${book.totalPages} trang',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (onAdd != null) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm vào kệ'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _statusChip(book.status.label, book.status.color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: AppTypography.caption.copyWith(color: color)),
    );
  }
}

import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../components/app_chip.dart';
import '../../components/progress_bar.dart';
import '../../data/mock_data.dart';
import '../../models/book.dart';
import '../../models/note.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../notes/note_edit_screen.dart';
import '../notes/notes_list_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;
  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late BookStatus status = widget.book.status;
  late int readPages = widget.book.readPages;
  late int totalPages = widget.book.totalPages;

  @override
  Widget build(BuildContext context) {
    final bookNotes = notes.where((n) => n.bookId == widget.book.id).toList();
    final progress = totalPages == 0
        ? 0.0
        : (readPages / totalPages).clamp(0, 1).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chi tiết sách',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CoverSection(
              book: widget.book,
              status: status,
              onStatusTap: (s) => setState(() => status = s),
            ),
            const SizedBox(height: 12),
            _DescriptionSection(text: widget.book.description),
            const SizedBox(height: 12),
            _ProgressSection(
              progress: progress,
              readPages: readPages,
              totalPages: totalPages,
              onReadChanged: (v) => setState(() => readPages = v),
              onTotalChanged: (v) => setState(() => totalPages = v),
              onUpdate: () {},
            ),
            const SizedBox(height: 12),
            _NotesSection(bookNotes: bookNotes, onAddNote: _goToAddNote),
            const SizedBox(height: 12),
            const _InfoSection(),
          ],
        ),
      ),
    );
  }

  void _goToAddNote() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditScreen(
          bookTitle: widget.book.title,
          bookId: widget.book.id,
        ),
      ),
    );
  }
}

class _CoverSection extends StatelessWidget {
  final Book book;
  final BookStatus status;
  final ValueChanged<BookStatus> onStatusTap;

  const _CoverSection({
    required this.book,
    required this.status,
    required this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 128,
            height: 192,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(
                  book.coverUrl ?? 'https://placehold.co/128x192',
                ),
                fit: BoxFit.cover,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 15,
                  offset: Offset(0, 10),
                  spreadRadius: -3,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 192,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: AppTypography.h1.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(book.author, style: AppTypography.body),
                  const SizedBox(height: 10),
                  _StatusPill(status: status, onTap: onStatusTap),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Chia sẻ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textBody,
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final BookStatus status;
  final ValueChanged<BookStatus> onTap;

  const _StatusPill({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BookStatus.values
          .map(
            (s) => AppChip(
              label: s.label,
              selected: status == s,
              onTap: () => onTap(s),
            ),
          )
          .toList(),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final String text;
  const _DescriptionSection({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mô tả', style: AppTypography.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text(text, style: AppTypography.body),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final double progress;
  final int readPages;
  final int totalPages;
  final ValueChanged<int> onReadChanged;
  final ValueChanged<int> onTotalChanged;
  final VoidCallback onUpdate;

  const _ProgressSection({
    required this.progress,
    required this.readPages,
    required this.totalPages,
    required this.onReadChanged,
    required this.onTotalChanged,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final readController = TextEditingController(text: '$readPages');
    final totalController = TextEditingController(text: '$totalPages');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tiến độ đọc', style: AppTypography.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          ProgressBar(value: progress),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$readPages / $totalPages',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: AppTypography.bodyBold,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OutlinedInput(
                  label: 'Trang đã đọc',
                  controller: readController,
                  onChanged: (v) => onReadChanged(int.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OutlinedInput(
                  label: 'Tổng số trang',
                  controller: totalController,
                  onChanged: (v) => onTotalChanged(int.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: 'Cập nhật tiến độ', onPressed: onUpdate),
        ],
      ),
    );
  }
}

class _OutlinedInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _OutlinedInput({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.body),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: InputBorder.none),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _NotesSection extends StatelessWidget {
  final List<Note> bookNotes;
  final VoidCallback onAddNote;

  const _NotesSection({required this.bookNotes, required this.onAddNote});

  void _viewAllNotes(BuildContext context) {
    final book = books.firstWhere((b) => b.id == bookNotes.first.bookId);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => NotesListScreen(book: book)));
  }

  @override
  Widget build(BuildContext context) {
    final keyIdeasCount = bookNotes.where((n) => n.isKeyIdea).length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ghi chú của tôi',
                style: AppTypography.h2.copyWith(fontSize: 18),
              ),
              Text(
                '${bookNotes.length} ghi chú',
                style: AppTypography.body.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick stats
          if (bookNotes.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 6),
                  Text(
                    '$keyIdeasCount ý chính',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${bookNotes.length - keyIdeasCount} ghi chú thường',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),

          if (bookNotes.isEmpty)
            Text(
              'Chưa có ghi chú',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            )
          else
            Column(
              children: bookNotes
                  .take(3)
                  .map(
                    (n) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x14F5A623),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFEF3C6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Trang ${n.page ?? "-"}',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              if (n.isKeyIdea) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n.content,
                            style: AppTypography.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddNote,
                  icon: const Icon(
                    Icons.add,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  label: const Text('Thêm ghi chú'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (bookNotes.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewAllNotes(context),
                    icon: const Icon(
                      Icons.list_alt,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    label: const Text('Xem tất cả'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection();

  @override
  Widget build(BuildContext context) {
    final rows = <Map<String, String>>[
      {'label': 'Tác giả', 'value': 'James Clear'},
      {'label': 'Số trang', 'value': '320 trang'},
      {'label': 'Thể loại', 'value': 'Tự phát triển, Thói quen'},
      {'label': 'Ngôn ngữ', 'value': 'Tiếng Việt'},
      {'label': 'Năm xuất bản', 'value': '2018'},
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin sách',
            style: AppTypography.h2.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (r) => Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    r['label']!,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(r['value']!, style: AppTypography.bodyBold),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

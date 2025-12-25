import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../components/progress_bar.dart';
import '../../data/services/book_service.dart';
import '../../data/services/notes_service.dart';
import '../../models/book.dart';
import '../../models/note.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../notes/create_note_screen.dart';
import '../notes/notes_list_screen.dart';
import '../notes/ocr_note_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;
  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final _notesService = NotesService();
  final _bookService = BookService();
  late BookStatus status = widget.book.status;
  late int readPages = widget.book.readPages;
  late int totalPages = widget.book.totalPages;
  late final TextEditingController _readController =
      TextEditingController(text: widget.book.readPages.toString());
  late final TextEditingController _totalController =
      TextEditingController(text: widget.book.totalPages.toString());
  List<Note> _bookNotes = [];
  bool _isLoadingNotes = true;
  bool _isUpdatingProgress = false;

  @override
  void initState() {
    super.initState();
    _readController.addListener(_handleReadChanged);
    _totalController.addListener(_handleTotalChanged);
    _loadNotes();
  }

  @override
  void didUpdateWidget(covariant BookDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.id != widget.book.id) {
      status = widget.book.status;
      readPages = widget.book.readPages;
      totalPages = widget.book.totalPages;
      _readController.text = widget.book.readPages.toString();
      _totalController.text = widget.book.totalPages.toString();
    }
  }

  @override
  void dispose() {
    _readController.removeListener(_handleReadChanged);
    _totalController.removeListener(_handleTotalChanged);
    _readController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    try {
      final notes = await _notesService.getNotesByBook(widget.book.id);
      if (mounted) {
        setState(() {
          _bookNotes = notes;
          _isLoadingNotes = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingNotes = false;
        });
      }
    }
  }

  void _handleReadChanged() {
    final value = int.tryParse(_readController.text) ?? 0;
    if (value != readPages) {
      setState(() => readPages = value);
    }
  }

  void _handleTotalChanged() {
    final value = int.tryParse(_totalController.text) ?? 0;
    if (value != totalPages) {
      setState(() => totalPages = value);
    }
  }

  Future<void> _updateProgress() async {
    final int parsedRead = int.tryParse(_readController.text) ?? 0;
    final int parsedTotal = int.tryParse(_totalController.text) ?? 0;

    int safeTotal = parsedTotal;
    int safeRead = parsedRead;
    if (safeTotal < 0) safeTotal = 0;
    if (safeRead < 0) safeRead = 0;
    if (safeTotal == 0 && safeRead > 0) {
      // If user only entered read pages, assume total equals that value to compute progress.
      safeTotal = safeRead;
    }
    if (safeRead > safeTotal && safeTotal > 0) {
      safeRead = safeTotal;
    }

    BookStatus newStatus = status;
    if (safeTotal > 0 && safeRead >= safeTotal) {
      newStatus = BookStatus.read;
    } else if (safeRead > 0) {
      newStatus = BookStatus.reading;
    } else {
      newStatus = BookStatus.wantToRead;
    }

    setState(() {
      _isUpdatingProgress = true;
      readPages = safeRead;
      totalPages = safeTotal;
      status = newStatus;
      _readController.text = safeRead.toString();
      _totalController.text = safeTotal.toString();
    });

    final updatedBook = widget.book.copyWith(
      readPages: safeRead,
      totalPages: safeTotal,
      status: newStatus,
    );

    final ok = await _bookService.upsertBook(updatedBook);
    if (!mounted) return;

    setState(() => _isUpdatingProgress = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Đã cập nhật tiến độ' : 'Lưu tiến độ thất bại'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = totalPages == 0 ? 0.0 : (readPages / totalPages).clamp(0, 1).toDouble();

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
            ),
            const SizedBox(height: 12),
            _DescriptionSection(text: widget.book.description),
            const SizedBox(height: 12),
            _ProgressSection(
              progress: progress,
              readController: _readController,
              totalController: _totalController,
              onUpdate: _isUpdatingProgress ? null : _updateProgress,
              isLoading: _isUpdatingProgress,
            ),
            const SizedBox(height: 12),
            _NotesSection(
              book: widget.book,
              bookNotes: _bookNotes,
              isLoading: _isLoadingNotes,
              onAddNote: _goToAddNote,
              onAddOCR: _goToOCR,
            ),
            const SizedBox(height: 12),
            const _InfoSection(),
          ],
        ),
      ),
    );
  }

  Future<void> _goToAddNote() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreateNoteScreen(book: widget.book)),
    );
    if (result == true) {
      _loadNotes();
    }
  }

  Future<void> _goToOCR() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OCRNoteScreen(book: widget.book)),
    );
    if (result == true) {
      _loadNotes();
    }
  }
}

class _CoverSection extends StatelessWidget {
  final Book book;
  final BookStatus status;

  const _CoverSection({
    required this.book,
    required this.status,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  book.title,
                  style: AppTypography.h1.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 6),
                Text(book.author, style: AppTypography.body),
                const SizedBox(height: 10),
                _StatusBadge(status: status),
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
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BookStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border, width: 1.2),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        status.label,
        style: AppTypography.body.copyWith(
          color: colors.text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _BadgeColors _statusColors(BookStatus status) {
    switch (status) {
      case BookStatus.reading:
        return _BadgeColors(
          background: const Color(0xFFFFFBEB),
          border: const Color(0xFFFDE585),
          text: const Color(0xFFBA4C00),
        );
      case BookStatus.wantToRead:
        return _BadgeColors(
          background: const Color(0xFFEFF3FF),
          border: const Color(0xFFD6E0FF),
          text: AppColors.primary,
        );
      case BookStatus.read:
        return _BadgeColors(
          background: const Color(0xFFE8F6EF),
          border: const Color(0xFFC4E8D5),
          text: AppColors.success,
        );
    }
  }
}

class _BadgeColors {
  final Color background;
  final Color border;
  final Color text;

  const _BadgeColors({
    required this.background,
    required this.border,
    required this.text,
  });
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
  final TextEditingController readController;
  final TextEditingController totalController;
  final VoidCallback? onUpdate;
  final bool isLoading;

  const _ProgressSection({
    required this.progress,
    required this.readController,
    required this.totalController,
    required this.onUpdate,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
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
                '${readController.text} / ${totalController.text}',
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
                  onChanged: null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OutlinedInput(
                  label: 'Tổng số trang',
                  controller: totalController,
                  onChanged: null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: isLoading ? 'Đang lưu...' : 'Cập nhật tiến độ',
            onPressed: onUpdate,
          ),
        ],
      ),
    );
  }
}

class _OutlinedInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

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
  final Book book;
  final List<Note> bookNotes;
  final bool isLoading;
  final VoidCallback onAddNote;
  final VoidCallback onAddOCR;

  const _NotesSection({
    required this.book,
    required this.bookNotes,
    required this.isLoading,
    required this.onAddNote,
    required this.onAddOCR,
  });

  void _viewAllNotes(BuildContext context) {
    if (bookNotes.isEmpty) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => NotesListScreen(book: book)));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

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
                color: AppColors.primary.withValues(alpha: 0.05),
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
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddOCR,
                  icon: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  label: const Text('Chụp OCR'),
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
      {'label': 'Thể loại', 'value': 'Phát triển, Thói quen'},
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

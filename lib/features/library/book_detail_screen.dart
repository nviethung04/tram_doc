import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../components/progress_bar.dart';
import '../../data/services/activities_service.dart';
import '../../data/services/book_service.dart';
import '../../data/services/google_books_service.dart';
import '../../data/services/notes_service.dart';
import '../../models/activity.dart';
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
  final _activitiesService = ActivitiesService();
  final _googleBooksService = GoogleBooksService();
  late BookStatus status = widget.book.status;
  late int readPages = widget.book.readPages;
  late int totalPages = widget.book.totalPages;
  late final TextEditingController _readController = TextEditingController(
    text: widget.book.readPages.toString(),
  );
  late final TextEditingController _totalController = TextEditingController(
    text: widget.book.totalPages.toString(),
  );
  List<Note> _bookNotes = [];
  bool _isLoadingNotes = true;
  bool _isUpdatingProgress = false;
  Book? _resolvedBook;

  @override
  void initState() {
    super.initState();
    _readController.addListener(_handleReadChanged);
    _totalController.addListener(_handleTotalChanged);
    _loadBookInfo();
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
      _resolvedBook = null;
      _loadBookInfo();
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

  Future<void> _loadBookInfo() async {
    Book? current = widget.book;
    try {
      final fromDb = await _bookService.getBookById(widget.book.id);
      if (fromDb != null) {
        current = fromDb;
      }
      final needsDetails =
          current.categories.isEmpty ||
          (current.language == null || current.language!.isEmpty) ||
          current.publishedYear == null;
      if (needsDetails && (current.isbn?.isNotEmpty ?? false)) {
        final fromApi = await _googleBooksService.lookupIsbn(current.isbn!);
        if (fromApi != null) {
          current = current.copyWith(
            categories: fromApi.categories.isNotEmpty
                ? fromApi.categories
                : current.categories,
            language: (fromApi.language?.isNotEmpty ?? false)
                ? fromApi.language
                : current.language,
            publishedYear: fromApi.publishedYear ?? current.publishedYear,
          );
          await _bookService.upsertBook(current);
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _resolvedBook = current);
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
              onShare: _shareActivity,
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
            _InfoSection(book: _resolvedBook ?? widget.book),
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
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => OCRNoteScreen(book: widget.book)));
    if (result == true) {
      _loadNotes();
    }
  }

  Future<void> _shareActivity() async {
    String message;
    ActivityType type;
    switch (status) {
      case BookStatus.wantToRead:
        message = 'vừa thêm vào kệ "Muốn đọc"';
        type = ActivityType.bookAdded;
        break;
      case BookStatus.reading:
        message = 'đang đọc';
        type = ActivityType.bookAdded;
        break;
      case BookStatus.read:
        message = 'vừa đọc xong';
        type = ActivityType.bookFinished;
        break;
    }
    await _openShareSheet(message, type);
  }

  Future<void> _openShareSheet(String message, ActivityType type) async {
    if (!mounted) return;
    final rootContext = context;
    await showModalBottomSheet<void>(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _ShareSheet(
          book: widget.book,
          status: status,
          initialMessage: message,
          type: type,
          activitiesService: _activitiesService,
          rootContext: rootContext,
        );
      },
    );
  }
}

class _CoverSection extends StatelessWidget {
  final Book book;
  final BookStatus status;
  final VoidCallback onShare;

  const _CoverSection({
    required this.book,
    required this.status,
    required this.onShare,
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
                  onPressed: onShare,
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

class _ShareSheet extends StatefulWidget {
  final Book book;
  final BookStatus status;
  final String initialMessage;
  final ActivityType type;
  final ActivitiesService activitiesService;
  final BuildContext rootContext;

  const _ShareSheet({
    required this.book,
    required this.status,
    required this.initialMessage,
    required this.type,
    required this.activitiesService,
    required this.rootContext,
  });

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialMessage,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final finalMessage = _controller.text.trim();
    if (finalMessage.isEmpty) return;
    try {
      await widget.activitiesService.createActivity(
        type: widget.type,
        bookId: widget.book.id,
        bookTitle: widget.book.title,
        bookAuthor: widget.book.author,
        bookCoverUrl: widget.book.coverUrl,
        message: finalMessage,
        isPublic: true,
        visibility: 'public',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        widget.rootContext,
      ).showSnackBar(const SnackBar(content: Text('Đã chia sẻ vào hoạt động')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        widget.rootContext,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.6;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tạo chia sẻ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 90,
                        child:
                            widget.book.coverUrl != null &&
                                widget.book.coverUrl!.isNotEmpty
                            ? Image.network(
                                widget.book.coverUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                child: Icon(
                                  Icons.menu_book,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.book.title,
                            style: AppTypography.bodyBold.copyWith(
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.book.author,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          _StatusBadge(status: widget.status),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Caption',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Đăng'),
                  ),
                ),
              ),
            ],
          ),
        ),
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
          child: Center(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onChanged,
            ),
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
                child: OutlinedButton(
                  onPressed: onAddNote,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Thêm ghi chú',
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                child: OutlinedButton(
                  onPressed: onAddOCR,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Chụp OCR',
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  child: OutlinedButton(
                    onPressed: () => _viewAllNotes(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.list_alt,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Xem tất cả',
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        ),
                      ],
                    ),
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
  final Book book;
  const _InfoSection({required this.book});

  String _formatLanguage(String? language) {
    final value = language?.trim();
    if (value == null || value.isEmpty) return '-';
    final normalized = value.toLowerCase();
    if (normalized == 'vi' ||
        normalized == 'vie' ||
        normalized == 'vnm' ||
        normalized == 'vi-vn') {
      return 'Tiếng Việt';
    }
    if (normalized == 'en' || normalized == 'eng' || normalized == 'en-us') {
      return 'Tiếng Anh';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final author = book.author.trim().isNotEmpty ? book.author.trim() : '-';
    final totalPages =
        book.totalPages > 0 ? '${book.totalPages} trang' : '-';
    final categories = book.categories.isNotEmpty
        ? book.categories.join(', ')
        : '-';
    final language = _formatLanguage(book.language);
    final publishedYear = (book.publishedYear ?? 0) > 0
        ? book.publishedYear.toString()
        : '-';

    final rows = <Map<String, String>>[
      {'label': 'Tác giả', 'value': author},
      {'label': 'Số trang', 'value': totalPages},
      {'label': 'Thể loại', 'value': categories},
      {'label': 'Ngôn ngữ', 'value': language},
      {'label': 'Năm xuất bản', 'value': publishedYear},
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


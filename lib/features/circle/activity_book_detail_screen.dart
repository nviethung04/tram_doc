import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/services/book_service.dart';
import '../../data/services/google_books_service.dart';
import '../../models/activity.dart';
import '../../models/book.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class ActivityBookDetailScreen extends StatefulWidget {
  final Activity activity;
  final Book? book;

  const ActivityBookDetailScreen({
    super.key,
    required this.activity,
    required this.book,
  });

  @override
  State<ActivityBookDetailScreen> createState() =>
      _ActivityBookDetailScreenState();
}

class _ActivityBookDetailScreenState extends State<ActivityBookDetailScreen> {
  final _bookService = BookService();
  final _googleBooksService = GoogleBooksService();
  final _firestore = FirebaseFirestore.instance;

  Book? _resolvedBook;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadBookInfo();
  }

  Future<void> _loadBookInfo() async {
    Book current = widget.book ?? _createBookFromActivity(widget.activity);
    try {
      if (widget.activity.bookId != null &&
          widget.activity.bookId!.isNotEmpty) {
        final fromDb = await _bookService.getBookById(widget.activity.bookId!);
        if (fromDb != null) {
          current = fromDb;
        }
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
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _resolvedBook = current);
  }

  Book _createBookFromActivity(Activity activity) {
    return Book(
      id: '',
      title: activity.bookTitle?.isNotEmpty == true
          ? activity.bookTitle!
          : 'Sách mới',
      author: activity.bookAuthor?.isNotEmpty == true
          ? activity.bookAuthor!
          : 'Không rõ tác giả',
      coverUrl: activity.bookCoverUrl,
      status: BookStatus.wantToRead,
      readPages: 0,
      totalPages: 0,
      description: activity.message?.isNotEmpty == true
          ? activity.message!
          : 'Chưa có mô tả',
    );
  }

  Book _copyToLibraryBook(Book book) {
    return Book(
      id: '',
      title: book.title,
      author: book.author,
      coverUrl: book.coverUrl,
      isbn: book.isbn,
      status: BookStatus.wantToRead,
      readPages: 0,
      totalPages: book.totalPages,
      description: book.description,
      categories: book.categories,
      language: book.language,
      publishedYear: book.publishedYear,
    );
  }

  Future<bool> _isBookInLibraryByTitle(String title, String userId) async {
    try {
      var query =
          _firestore.collection('books').where('userId', isEqualTo: userId);
      query = query.where('title', isEqualTo: title);
      final snap = await query.limit(1).get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _addToLibrary() async {
    if (_isAdding) return;
    final messenger = ScaffoldMessenger.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thêm sách')),
      );
      return;
    }

    final source = _resolvedBook ?? widget.book ?? _createBookFromActivity(
      widget.activity,
    );

    setState(() => _isAdding = true);
    try {
      final alreadyInLibrary =
          await _isBookInLibraryByTitle(source.title, currentUserId);
      if (alreadyInLibrary) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Sách đã có trong thư viện')),
        );
        return;
      }

      final ok = await _bookService.upsertBook(_copyToLibraryBook(source));
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Đã thêm vào tủ sách' : 'Không thể thêm sách',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = _resolvedBook ?? widget.book ?? _createBookFromActivity(
      widget.activity,
    );

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
              book: book,
              isAdding: _isAdding,
              onAdd: _addToLibrary,
            ),
            const SizedBox(height: 12),
            _DescriptionSection(text: book.description),
            const SizedBox(height: 12),
            _InfoSection(book: book),
          ],
        ),
      ),
    );
  }
}

class _CoverSection extends StatelessWidget {
  final Book book;
  final VoidCallback onAdd;
  final bool isAdding;

  const _CoverSection({
    required this.book,
    required this.onAdd,
    required this.isAdding,
  });

  @override
  Widget build(BuildContext context) {
    final title = book.title.trim().isNotEmpty ? book.title : 'Chưa có tiêu đề';
    final author =
        book.author.trim().isNotEmpty ? book.author : 'Không rõ tác giả';

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
                  title,
                  style: AppTypography.h1.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 6),
                Text(author, style: AppTypography.body),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isAdding ? null : onAdd,
                  icon: const Icon(Icons.library_add_outlined, size: 18),
                  label: Text(isAdding ? 'Đang thêm...' : 'Thêm vào tủ sách'),
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

class _DescriptionSection extends StatelessWidget {
  final String text;
  const _DescriptionSection({required this.text});

  @override
  Widget build(BuildContext context) {
    final description =
        text.trim().isNotEmpty ? text : 'Chưa có mô tả cho sách này';
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mô tả', style: AppTypography.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text(description, style: AppTypography.body),
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
    final totalPages = book.totalPages > 0 ? '${book.totalPages} trang' : '-';
    final categories =
        book.categories.isNotEmpty ? book.categories.join(', ') : '-';
    final language = _formatLanguage(book.language);
    final publishedYear =
        (book.publishedYear ?? 0) > 0 ? book.publishedYear.toString() : '-';

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
            (row) => Container(
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
                    row['label']!,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(row['value']!, style: AppTypography.bodyBold),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

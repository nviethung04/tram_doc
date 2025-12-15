import 'package:flutter/material.dart';
import '../../../components/app_button.dart';
import '../../../components/app_input.dart';
import '../../../data/services/book_service.dart';
import '../../../models/book.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class BooksManagementScreen extends StatefulWidget {
  const BooksManagementScreen({super.key});

  @override
  State<BooksManagementScreen> createState() => _BooksManagementScreenState();
}

class _BooksManagementScreenState extends State<BooksManagementScreen> {
  final BookService _bookService = BookService();
  final TextEditingController _searchController = TextEditingController();

  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);

    final books = await _bookService.getAllBooks();

    setState(() {
      _books = books;
      _filteredBooks = books;
      _isLoading = false;
    });
  }

  void _filterBooks(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBooks = _books;
      } else {
        _filteredBooks = _books
            .where(
              (book) =>
                  book.title.toLowerCase().contains(query.toLowerCase()) ||
                  book.author.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _deleteBook(Book book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa sách "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _bookService.deleteBook(book.id);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa sách thành công')));
        _loadBooks();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lỗi khi xóa sách')));
      }
    }
  }

  void _showBookDialog({Book? book}) {
    showDialog(
      context: context,
      builder: (context) => _BookFormDialog(
        book: book,
        onSave: () {
          Navigator.pop(context);
          _loadBooks();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sách'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppInput(
              controller: _searchController,
              label: 'Tìm kiếm sách',
              hintText: 'Nhập tên sách hoặc tác giả',
              prefixIcon: Icons.search,
              onChanged: _filterBooks,
            ),
          ),

          // Books list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBooks.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Chưa có sách nào'
                          : 'Không tìm thấy sách',
                      style: AppTypography.body1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    itemCount: _filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = _filteredBooks[index];
                      return _BookCard(
                        book: book,
                        onEdit: () => _showBookDialog(book: book),
                        onDelete: () => _deleteBook(book),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBookDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BookCard({
    required this.book,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Cover image
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                image: book.coverUrl != null
                    ? DecorationImage(
                        image: NetworkImage(book.coverUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: book.coverUrl == null
                  ? const Icon(Icons.book, color: AppColors.textSecondary)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),

            // Book info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    book.author,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${book.totalPages} trang',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookFormDialog extends StatefulWidget {
  final Book? book;
  final VoidCallback onSave;

  const _BookFormDialog({this.book, required this.onSave});

  @override
  State<_BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends State<_BookFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final BookService _bookService = BookService();

  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _descriptionController;
  late TextEditingController _coverUrlController;
  late TextEditingController _totalPagesController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book?.title ?? '');
    _authorController = TextEditingController(text: widget.book?.author ?? '');
    _descriptionController = TextEditingController(
      text: widget.book?.description ?? '',
    );
    _coverUrlController = TextEditingController(
      text: widget.book?.coverUrl ?? '',
    );
    _totalPagesController = TextEditingController(
      text: widget.book?.totalPages.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _coverUrlController.dispose();
    _totalPagesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final book = Book(
      id: widget.book?.id ?? '',
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      description: _descriptionController.text.trim(),
      coverUrl: _coverUrlController.text.trim().isEmpty
          ? null
          : _coverUrlController.text.trim(),
      totalPages: int.tryParse(_totalPagesController.text) ?? 0,
      status: widget.book?.status ?? BookStatus.wantToRead,
      readPages: widget.book?.readPages ?? 0,
    );

    bool success;
    if (widget.book == null) {
      // Create new book
      final bookId = await _bookService.createBook(book);
      success = bookId != null;
    } else {
      // Update existing book
      success = await _bookService.updateBook(widget.book!.id, book);
    }

    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.book == null
                ? 'Đã thêm sách thành công'
                : 'Đã cập nhật sách thành công',
          ),
        ),
      );
      widget.onSave();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Có lỗi xảy ra')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.book == null ? 'Thêm sách mới' : 'Chỉnh sửa sách',
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.lg),

                AppInput(
                  controller: _titleController,
                  label: 'Tên sách *',
                  hintText: 'Nhập tên sách',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên sách';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                AppInput(
                  controller: _authorController,
                  label: 'Tác giả *',
                  hintText: 'Nhập tên tác giả',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên tác giả';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                AppInput(
                  controller: _descriptionController,
                  label: 'Mô tả',
                  hintText: 'Nhập mô tả sách',
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.md),

                AppInput(
                  controller: _coverUrlController,
                  label: 'URL ảnh bìa',
                  hintText: 'Nhập URL ảnh bìa',
                ),
                const SizedBox(height: AppSpacing.md),

                AppInput(
                  controller: _totalPagesController,
                  label: 'Số trang *',
                  hintText: 'Nhập số trang',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số trang';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Số trang không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AppButton(
                      text: widget.book == null ? 'Thêm' : 'Cập nhật',
                      onPressed: _isSaving ? null : _save,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

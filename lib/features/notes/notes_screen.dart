import 'package:flutter/material.dart';
import '../../components/primary_app_bar.dart';
import '../../components/notification_bell.dart';
import '../../data/services/notes_service.dart';
import '../../data/services/flashcard_service.dart';
import '../../data/services/book_service.dart';
import '../../models/note.dart';
import '../../models/book.dart';
import 'note_detail_screen.dart';
import 'ocr_note_screen.dart';
import 'create_note_screen.dart';
import '../flashcards/flashcard_overview_screen.dart';
import '../notifications/notification_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => NotesScreenState();
}

class NotesScreenState extends State<NotesScreen> {
  final _notesService = NotesService();
  final _flashcardService = FlashcardService();
  final _bookService = BookService();
  List<Note> _allNotes = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _dueFlashcardsCount = 0;
  int _totalFlashcardsCount = 0;

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Public method để refresh data từ bên ngoài
  Future<void> refreshData() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load all notes for current user (across all books)
      final notes = await _notesService.getAllNotes();
      final dueFlashcards = await _flashcardService.getDueFlashcards();
      final allFlashcards = await _flashcardService.getAllFlashcards();

      if (mounted) {
        setState(() {
          _allNotes = notes;
          _dueFlashcardsCount = dueFlashcards.length;
          _totalFlashcardsCount = allFlashcards.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Notes & Flashcards',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: _showBookSelectionForManualNote,
            tooltip: 'Thêm ghi chú',
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _showBookSelectionForOCR,
            tooltip: 'Chụp ảnh OCR',
          ),
          NotificationBell(onPressed: _openNotifications),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          : _allNotes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có ghi chú',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thêm ghi chú từ các cuốn sách trong thư viện',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Flashcard overview card
                  if (_dueFlashcardsCount > 0)
                    Card(
                      color: Colors.amber[50],
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FlashcardOverviewScreen(),
                            ),
                          );
                          _loadData();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bolt,
                                color: Colors.amber,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Ôn tập hôm nay',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '$_dueFlashcardsCount flashcard đang chờ',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Notes stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: Icons.note,
                          count: _allNotes.length,
                          label: 'Tổng ghi chú',
                        ),
                        _StatItem(
                          icon: Icons.star,
                          count: _allNotes.where((n) => n.isKeyIdea).length,
                          label: 'Ý chính',
                          color: Colors.amber,
                        ),
                        _StatItem(
                          icon: Icons.credit_card,
                          count: _totalFlashcardsCount,
                          label: 'Flashcards',
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  // Recent notes header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Ghi chú gần đây',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Notes list
                  ..._allNotes
                      .take(20)
                      .map(
                        (note) => Dismissible(
                          key: Key('note_${note.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Xóa ghi chú?'),
                                content: const Text(
                                  'Bạn có chắc chắn muốn xóa ghi chú này? Hành động này không thể hoàn tác.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Xóa'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              try {
                                await _notesService.deleteNote(note.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã xóa ghi chú'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  _loadData();
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Lỗi khi xóa: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                            return confirmed;
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(note.bookTitle),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    note.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      if (note.page != null)
                                        Text(
                                          'Trang ${note.page}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      if (note.isKeyIdea)
                                        const Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.amber,
                                        ),
                                      if (note.isFlashcard)
                                        const Icon(
                                          Icons.credit_card,
                                          size: 14,
                                          color: Colors.green,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        NoteDetailScreen(note: note),
                                  ),
                                );
                                // Refresh data nếu có thay đổi (tạo flashcard, etc.)
                                if (result == true || result == null) {
                                  _loadData();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FlashcardOverviewScreen()),
          );
        },
        icon: const Icon(Icons.style),
        label: const Text('Flashcards'),
      ),
    );
  }

  Future<List<Book>> _getAvailableBooks() async {
    final books = <Book>{};
    for (final note in _allNotes) {
      if (note.bookId.isNotEmpty && note.bookTitle.isNotEmpty) {
        books.add(
          Book(
            id: note.bookId,
            title: note.bookTitle,
            author: '',
            description: '',
            coverUrl: null,
            status: BookStatus.wantToRead,
            readPages: 0,
            totalPages: 0,
          ),
        );
      }
    }

    // Nếu không có sách nào, lấy từ BookService
    if (books.isEmpty) {
      final allBooks = await _bookService.getAllBooks();
      books.addAll(allBooks);
    }

    return books.toList();
  }

  Future<void> _showBookSelectionForManualNote() async {
    try {
      final books = await _getAvailableBooks();

      if (books.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa có sách nào. Vui lòng thêm sách vào thư viện trước.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Hiển thị dialog chọn sách
      final selectedBook = await showDialog<Book>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chọn sách'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return ListTile(
                  leading: const Icon(Icons.book),
                  title: Text(book.title),
                  subtitle: book.author.isNotEmpty ? Text(book.author) : null,
                  onTap: () => Navigator.of(context).pop(book),
                );
              },
            ),
          ),
        ),
      );

      if (selectedBook != null && mounted) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CreateNoteScreen(book: selectedBook),
          ),
        );
        if (result == true) {
          _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showBookSelectionForOCR() async {
    try {
      final books = await _getAvailableBooks();

      if (books.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa có sách nào. Vui lòng thêm sách vào thư viện trước.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Hiển thị dialog chọn sách
      final selectedBook = await showDialog<Book>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chọn sách'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return ListTile(
                  leading: const Icon(Icons.book),
                  title: Text(book.title),
                  subtitle: book.author.isNotEmpty ? Text(book.author) : null,
                  onTap: () => Navigator.of(context).pop(book),
                );
              },
            ),
          ),
        ),
      );

      if (selectedBook != null && mounted) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OCRNoteScreen(book: selectedBook)),
        );
        if (result == true) {
          _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color? color;

  const _StatItem({
    required this.icon,
    required this.count,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blue, size: 28),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}

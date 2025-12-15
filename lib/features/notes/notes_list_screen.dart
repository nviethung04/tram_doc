import 'package:flutter/material.dart';
import '../../data/services/notes_service.dart';
import '../../models/book.dart';
import '../../models/note.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'create_note_screen.dart';
import 'note_detail_screen.dart';
import 'ocr_note_screen.dart';

enum NoteFilter { all, keyIdeas }

enum NoteSortBy { page, dateCreated }

class NotesListScreen extends StatefulWidget {
  final Book book;

  const NotesListScreen({super.key, required this.book});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final _notesService = NotesService();
  NoteFilter _currentFilter = NoteFilter.all;
  NoteSortBy _currentSort = NoteSortBy.page;
  List<Note> _allNotes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notes = await _notesService.getNotesByBook(widget.book.id);
      if (mounted) {
        setState(() {
          _allNotes = notes;
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

  List<Note> get _filteredAndSortedNotes {
    var bookNotes = List<Note>.from(_allNotes);

    // Apply filter
    if (_currentFilter == NoteFilter.keyIdeas) {
      bookNotes = bookNotes.where((note) => note.isKeyIdea).toList();
    }

    // Apply sort
    if (_currentSort == NoteSortBy.page) {
      bookNotes.sort((a, b) {
        if (a.page == null && b.page == null) return 0;
        if (a.page == null) return 1;
        if (b.page == null) return -1;
        return a.page!.compareTo(b.page!);
      });
    } else {
      bookNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return bookNotes;
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotes = _filteredAndSortedNotes;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ghi chú - ${widget.book.title}',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          PopupMenuButton<NoteSortBy>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() => _currentSort = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: NoteSortBy.page,
                child: Text('Sắp xếp theo trang'),
              ),
              const PopupMenuItem(
                value: NoteSortBy.dateCreated,
                child: Text('Sắp xếp theo ngày tạo'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: $_errorMessage'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadNotes,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Filter chips
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Tất cả (${_allNotes.length})',
                        isSelected: _currentFilter == NoteFilter.all,
                        onTap: () =>
                            setState(() => _currentFilter = NoteFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label:
                            'Ý chính (${_allNotes.where((n) => n.isKeyIdea).length})',
                        isSelected: _currentFilter == NoteFilter.keyIdeas,
                        onTap: () => setState(
                          () => _currentFilter = NoteFilter.keyIdeas,
                        ),
                      ),
                    ],
                  ),
                ),

                // Notes list
                Expanded(
                  child: filteredNotes.isEmpty
                      ? _EmptyState(filter: _currentFilter)
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredNotes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final note = filteredNotes[index];
                            return _NoteCard(
                              note: note,
                              onTap: () => _navigateToDetail(note),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'ocr',
            onPressed: () => _navigateToOCR(),
            backgroundColor: Colors.white,
            child: const Icon(Icons.camera_alt, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _navigateToCreate(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  void _navigateToCreate() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreateNoteScreen(book: widget.book)),
    );

    // Reload notes if something changed
    if (result == true) {
      _loadNotes();
    }
  }

  void _navigateToOCR() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => OCRNoteScreen(book: widget.book)));
  }

  void _navigateToDetail(Note note) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)));

    // Reload notes if something changed
    if (result == true) {
      _loadNotes();
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textBody,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const _NoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (note.page != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Trang ${note.page}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (note.isKeyIdea)
                  const Icon(Icons.star, size: 20, color: Colors.amber),
                const Spacer(),
                if (note.isFlashcard)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Flashcard',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              note.content,
              style: AppTypography.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final NoteFilter filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            filter == NoteFilter.keyIdeas
                ? Icons.star_border
                : Icons.note_add_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            filter == NoteFilter.keyIdeas
                ? 'Chưa có ý chính nào'
                : 'Chưa có ghi chú nào',
            style: AppTypography.h2.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            filter == NoteFilter.keyIdeas
                ? 'Đánh dấu ghi chú quan trọng làm ý chính'
                : 'Nhấn nút + để thêm ghi chú mới',
            style: AppTypography.body.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

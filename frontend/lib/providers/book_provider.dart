import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class BookProvider extends ChangeNotifier {
  List<Book> _books = [];
  List<Book> _wantToReadBooks = [];
  List<Book> _readingBooks = [];
  List<Book> _readBooks = [];

  bool _isLoading = false;
  String? _error;

  List<Book> get books => _books;
  List<Book> get wantToReadBooks => _wantToReadBooks;
  List<Book> get readingBooks => _readingBooks;
  List<Book> get readBooks => _readBooks;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _categorizeBooks() {
    _wantToReadBooks = _books
        .where((book) => book.status == BookStatus.wantToRead)
        .toList();
    _readingBooks = _books
        .where((book) => book.status == BookStatus.reading)
        .toList();
    _readBooks = _books
        .where((book) => book.status == BookStatus.read)
        .toList();
  }

  Future<void> fetchBooks({BookStatus? status, String? search}) async {
    try {
      setLoading(true);
      clearError();

      final fetchedBooks = await ApiService.getBooks(
        status: status,
        search: search,
      );

      if (status == null) {
        _books = fetchedBooks;
        _categorizeBooks();
      }

      setLoading(false);
    } catch (e) {
      setError(e.toString());
      setLoading(false);
    }
  }

  Future<bool> addBook({
    required String title,
    String? authors,
    String? isbn,
    String? googleId,
    String? publisher,
    String? publishDate,
    String? description,
    String? coverUrl,
    int? pageCount,
    BookStatus? status,
    String? location,
  }) async {
    try {
      setLoading(true);
      clearError();

      final newBook = await ApiService.createBook(
        title: title,
        authors: authors,
        isbn: isbn,
        googleId: googleId,
        publisher: publisher,
        publishDate: publishDate,
        description: description,
        coverUrl: coverUrl,
        pageCount: pageCount,
        status: status,
        location: location,
      );

      _books.add(newBook);
      _categorizeBooks();
      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  Future<bool> updateBook(int bookId, Map<String, dynamic> updates) async {
    try {
      setLoading(true);
      clearError();

      final updatedBook = await ApiService.updateBook(bookId, updates);

      final index = _books.indexWhere((book) => book.id == bookId);
      if (index != -1) {
        _books[index] = updatedBook;
        _categorizeBooks();
      }

      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  Future<bool> deleteBook(int bookId) async {
    try {
      setLoading(true);
      clearError();

      await ApiService.deleteBook(bookId);

      _books.removeWhere((book) => book.id == bookId);
      _categorizeBooks();

      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> searchBooks(String query) async {
    try {
      clearError();
      return await ApiService.searchBooks(query);
    } catch (e) {
      setError(e.toString());
      return [];
    }
  }

  Future<Map<String, dynamic>?> scanBarcode(String barcode) async {
    try {
      clearError();
      return await ApiService.scanBarcode(barcode);
    } catch (e) {
      setError(e.toString());
      return null;
    }
  }

  Book? getBookById(int bookId) {
    try {
      return _books.firstWhere((book) => book.id == bookId);
    } catch (e) {
      return null;
    }
  }

  void updateBookStatus(int bookId, BookStatus newStatus) {
    final index = _books.indexWhere((book) => book.id == bookId);
    if (index != -1) {
      final updatedBook = _books[index].copyWith(status: newStatus);
      _books[index] = updatedBook;
      _categorizeBooks();
      notifyListeners();

      // Update on server
      updateBook(bookId, {'status': newStatus.value});
    }
  }

  void updateBookProgress(int bookId, int progress) {
    final index = _books.indexWhere((book) => book.id == bookId);
    if (index != -1) {
      final updatedBook = _books[index].copyWith(progress: progress);
      _books[index] = updatedBook;
      notifyListeners();

      // Update on server
      updateBook(bookId, {'progress': progress});
    }
  }

  void updateBookRating(int bookId, int rating) {
    final index = _books.indexWhere((book) => book.id == bookId);
    if (index != -1) {
      final updatedBook = _books[index].copyWith(rating: rating);
      _books[index] = updatedBook;
      notifyListeners();

      // Update on server
      updateBook(bookId, {'rating': rating});
    }
  }

  // Statistics
  int get totalBooks => _books.length;
  int get booksWantToRead => _wantToReadBooks.length;
  int get booksReading => _readingBooks.length;
  int get booksRead => _readBooks.length;

  double get readingProgress {
    if (_books.isEmpty) return 0.0;
    return _readBooks.length / _books.length;
  }
}

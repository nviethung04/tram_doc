import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/book.dart';

class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'books';

  /// Lấy tất cả sách (cho admin)
  Future<List<Book>> getAllBooks() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting all books: $e');
      return [];
    }
  }

  /// Lấy sách theo ID
  Future<Book?> getBookById(String bookId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(bookId).get();
      if (!doc.exists) return null;
      return Book.fromFirestore(doc);
    } catch (e) {
      print('Error getting book: $e');
      return null;
    }
  }

  /// Thêm sách mới
  Future<String?> createBook(Book book) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(book.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating book: $e');
      return null;
    }
  }

  /// Cập nhật sách
  Future<bool> updateBook(String bookId, Book book) async {
    try {
      final data = book.toFirestore();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_collection).doc(bookId).update(data);
      return true;
    } catch (e) {
      print('Error updating book: $e');
      return false;
    }
  }

  /// Xóa sách
  Future<bool> deleteBook(String bookId) async {
    try {
      await _firestore.collection(_collection).doc(bookId).delete();
      return true;
    } catch (e) {
      print('Error deleting book: $e');
      return false;
    }
  }

  /// Tìm kiếm sách theo tên hoặc tác giả
  Future<List<Book>> searchBooks(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Book.fromFirestore(doc))
          .where(
            (book) =>
                book.title.toLowerCase().contains(query.toLowerCase()) ||
                book.author.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      print('Error searching books: $e');
      return [];
    }
  }

  /// Đếm tổng số sách
  Future<int> getBooksCount() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting books count: $e');
      return 0;
    }
  }
}

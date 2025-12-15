import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/book.dart';

/// Quản lý CRUD sách trong Firestore (collection gốc `books`, field userId để phân quyền).
class BookService {
  BookService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _collection = 'books';

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Lấy tất cả sách của user hiện tại.
  Future<List<Book>> getAllBooks() async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting all books: $e');
      return [];
    }
  }

  /// Lấy sách theo ID.
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

  /// Thêm sách mới.
  Future<String?> createBook(Book book) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    try {
      final bookWithUser = book.copyWith(userId: _currentUserId);
      final docRef = await _firestore.collection(_collection).add(bookWithUser.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating book: $e');
      return null;
    }
  }

  /// Cập nhật sách.
  Future<bool> updateBook(String bookId, Book book) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    try {
      final existingDoc = await _firestore.collection(_collection).doc(bookId).get();
      if (!existingDoc.exists || existingDoc.data()?['userId'] != _currentUserId) {
        throw Exception('Unauthorized or book not found');
      }
      final data = book.copyWith(userId: _currentUserId).toFirestore()
        ..['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_collection).doc(bookId).update(data);
      return true;
    } catch (e) {
      print('Error updating book: $e');
      return false;
    }
  }

  /// Xóa sách.
  Future<bool> deleteBook(String bookId) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    try {
      final existingDoc = await _firestore.collection(_collection).doc(bookId).get();
      if (!existingDoc.exists || existingDoc.data()?['userId'] != _currentUserId) {
        throw Exception('Unauthorized or book not found');
      }
      await _firestore.collection(_collection).doc(bookId).delete();
      return true;
    } catch (e) {
      print('Error deleting book: $e');
      return false;
    }
  }

  /// Tìm kiếm trong sách của user.
  Future<List<Book>> searchBooks(String query) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _currentUserId)
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

  /// Đếm số sách của user.
  Future<int> getBooksCount() async {
    if (_currentUserId == null) return 0;
    try {
      final querySnapshot =
          await _firestore.collection(_collection).where('userId', isEqualTo: _currentUserId).get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting books count: $e');
      return 0;
    }
  }

  /// Thêm hoặc cập nhật sách (theo id nếu có).
  Future<bool> upsertBook(Book book) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    try {
      final bookWithUser = book.copyWith(userId: _currentUserId);

      if (book.id.isNotEmpty) {
        final existingDoc = await _firestore.collection(_collection).doc(book.id).get();
        if (existingDoc.exists) {
          final existingUserId = existingDoc.data()?['userId'];
          if (existingUserId == null || existingUserId == _currentUserId) {
            final data = bookWithUser.toFirestore()
              ..['updatedAt'] = FieldValue.serverTimestamp();
            await _firestore.collection(_collection).doc(book.id).update(data);
          } else {
            throw Exception('Unauthorized to update this book');
          }
        } else {
          await _firestore.collection(_collection).doc(book.id).set(bookWithUser.toFirestore());
        }
      } else {
        await _firestore.collection(_collection).add(bookWithUser.toFirestore());
      }
      return true;
    } catch (e) {
      print('Error upserting book: $e');
      return false;
    }
  }

  /// Stream tất cả sách của user hiện tại.
  Stream<List<Book>> streamAllBooks() {
    if (_currentUserId == null) return const Stream<List<Book>>.empty();
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList());
  }

  /// Stream sách theo status.
  Stream<List<Book>> streamBooksByStatus(BookStatus status) {
    if (_currentUserId == null) return const Stream<List<Book>>.empty();
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: status.index)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList());
  }
}

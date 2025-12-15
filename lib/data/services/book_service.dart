import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/book.dart';

class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'books';

  // Lấy userId hiện tại
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Lấy tất cả sách của user hiện tại
  Future<List<Book>> getAllBooks() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

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
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final bookWithUser = book.copyWith(userId: _currentUserId);
      final docRef = await _firestore
          .collection(_collection)
          .add(bookWithUser.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating book: $e');
      return null;
    }
  }

  /// Cập nhật sách
  Future<bool> updateBook(String bookId, Book book) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Kiểm tra quyền sở hữu
      final existingDoc = await _firestore
          .collection(_collection)
          .doc(bookId)
          .get();
      if (!existingDoc.exists ||
          existingDoc.data()?['userId'] != _currentUserId) {
        throw Exception('Unauthorized or book not found');
      }

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
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Kiểm tra quyền sở hữu
      final existingDoc = await _firestore
          .collection(_collection)
          .doc(bookId)
          .get();
      if (!existingDoc.exists ||
          existingDoc.data()?['userId'] != _currentUserId) {
        throw Exception('Unauthorized or book not found');
      }

      await _firestore.collection(_collection).doc(bookId).delete();
      return true;
    } catch (e) {
      print('Error deleting book: $e');
      return false;
    }
  }

  /// Tìm kiếm sách theo tên hoặc tác giả (trong thư viện của user)
  Future<List<Book>> searchBooks(String query) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

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

  /// Đếm tổng số sách của user hiện tại
  Future<int> getBooksCount() async {
    try {
      if (_currentUserId == null) {
        return 0;
      }

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _currentUserId)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting books count: $e');
      return 0;
    }
  }

  /// Thêm hoặc cập nhật sách (upsert)
  Future<bool> upsertBook(Book book) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final bookWithUser = book.copyWith(userId: _currentUserId);

      if (book.id.isNotEmpty) {
        // Nếu có ID, kiểm tra xem document có tồn tại không
        final existingDoc = await _firestore
            .collection(_collection)
            .doc(book.id)
            .get();
        if (existingDoc.exists) {
          // Chỉ cập nhật nếu sách thuộc về user hoặc chưa có userId
          final existingUserId = existingDoc.data()?['userId'];
          if (existingUserId == null || existingUserId == _currentUserId) {
            final data = bookWithUser.toFirestore();
            data['updatedAt'] = FieldValue.serverTimestamp();
            await _firestore.collection(_collection).doc(book.id).update(data);
          } else {
            throw Exception('Unauthorized to update this book');
          }
        } else {
          // Nếu document không tồn tại, tạo mới
          await _firestore
              .collection(_collection)
              .add(bookWithUser.toFirestore());
        }
      } else {
        // Nếu không có ID, tạo sách mới
        await _firestore
            .collection(_collection)
            .add(bookWithUser.toFirestore());
      }
      return true;
    } catch (e) {
      print('Error upserting book: $e');
      return false;
    }
  }

  /// Stream tất cả sách của user hiện tại theo thời gian thực
  Stream<List<Book>> streamAllBooks() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList(),
        );
  }

  /// Lấy sách theo status của user hiện tại
  Future<List<Book>> getBooksByStatus(BookStatus status) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: status.index)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting books by status: $e');
      return [];
    }
  }

  /// Stream sách theo status của user hiện tại
  Stream<List<Book>> streamBooksByStatus(BookStatus status) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: status.index)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList(),
        );
  }
}

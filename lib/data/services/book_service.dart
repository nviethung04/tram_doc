import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/book.dart';

/// CRUD helpers for the books collection scoped by userId.
class BookService {
  BookService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _collection = 'books';

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Fetch all books for current user.
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

  /// Get a book by id.
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

  /// Create a new book.
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

  /// Update a book.
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

  /// Delete a book.
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

  /// Search books for the current user on the client side.
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

  /// Count books for the current user.
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

  /// Thống kê nhanh số sách tổng và đã đọc (status = read).
  Future<Map<String, int>> getBookStats() async {
    if (_currentUserId == null) return {'total': 0, 'read': 0};
    try {
      // Không orderBy để tránh yêu cầu index.
      final snap =
          await _firestore.collection(_collection).where('userId', isEqualTo: _currentUserId).get();
      int total = 0;
      int read = 0;
      for (final doc in snap.docs) {
        total += 1;
        final data = doc.data();
        final rawStatus = data['status'];
        BookStatus status;
        if (rawStatus is int && rawStatus >= 0 && rawStatus < BookStatus.values.length) {
          status = BookStatus.values[rawStatus];
        } else if (rawStatus is String) {
          status = BookStatusX.fromName(rawStatus);
        } else {
          status = BookStatus.wantToRead;
        }
        if (status == BookStatus.read) read += 1;
      }
      return {'total': total, 'read': read};
    } catch (e) {
      print('Error getting book stats: $e');
      return {'total': 0, 'read': 0};
    }
  }

  /// Add or update a book by id if provided.
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

  /// Stream all books for the current user.
  Stream<List<Book>> streamAllBooks() {
    if (_currentUserId == null) return const Stream<List<Book>>.empty();

    final baseQuery = _firestore.collection(_collection).where('userId', isEqualTo: _currentUserId);

    return () async* {
      // Try ordered stream; if it fails (e.g., missing index), fall back to unordered.
      try {
        await for (final snap in baseQuery.orderBy('createdAt', descending: true).snapshots()) {
          yield snap.docs.map((doc) => Book.fromFirestore(doc)).toList();
        }
      } catch (e) {
        print('streamAllBooks fallback without orderBy: $e');
        await for (final snap in baseQuery.snapshots()) {
          yield snap.docs.map((doc) => Book.fromFirestore(doc)).toList();
        }
      }
    }();
  }

  /// Stream books by status for the current user.
  Stream<List<Book>> streamBooksByStatus(BookStatus status) {
    if (_currentUserId == null) return const Stream<List<Book>>.empty();

    final baseQuery = _firestore
        .collection(_collection)
        .where('userId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: status.index);

    return () async* {
      try {
        await for (final snap in baseQuery.orderBy('createdAt', descending: true).snapshots()) {
          yield snap.docs.map((doc) => Book.fromFirestore(doc)).toList();
        }
      } catch (e) {
        print('streamBooksByStatus fallback without orderBy: $e');
        await for (final snap in baseQuery.snapshots()) {
          yield snap.docs.map((doc) => Book.fromFirestore(doc)).toList();
        }
      }
    }();
  }
}

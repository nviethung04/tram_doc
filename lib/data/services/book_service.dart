import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/book.dart';

/// Quản lý CRUD sách trong Firestore: users/{uid}/books/{bookId}
class BookService {
  BookService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _userBooks(String uid) =>
      _firestore.collection('users').doc(uid).collection('books');

  /// Stream toàn bộ sách của user.
  Stream<List<Book>> streamAllBooks() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream<List<Book>>.empty();
    return _userBooks(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Book.fromMap(d.data(), d.id)).toList());
  }

  /// Stream theo kệ (status).
  Stream<List<Book>> streamBooksByStatus(BookStatus status) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream<List<Book>>.empty();
    return _userBooks(uid)
        .where('status', isEqualTo: status.name)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Book.fromMap(d.data(), d.id)).toList());
  }

  Future<void> upsertBook(Book book) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Bạn chưa đăng nhập');
    await _userBooks(uid).doc(book.id).set(book.toMap(), SetOptions(merge: true));
  }

  Future<void> updateStatus(String bookId, BookStatus status) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Bạn chưa đăng nhập');
    await _userBooks(uid).doc(bookId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

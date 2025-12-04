import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tram_doc/models/book.dart';
import 'package:tram_doc/models/note.dart';
import 'package:tram_doc/models/flashcard.dart';
import 'package:tram_doc/models/user.dart' as app_user;

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth methods
  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user document in Firestore
    if (credential.user != null) {
      await createUserDocument(credential.user!.uid, email);
    }

    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // User document methods
  Future<void> createUserDocument(String userId, String email) async {
    final user = app_user.AppUser(
      id: userId,
      email: email,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _firestore.collection('users').doc(userId).set(user.toFirestore());
  }

  Future<app_user.AppUser?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return app_user.AppUser.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateUser(app_user.AppUser user) async {
    await _firestore
        .collection('users')
        .doc(user.id)
        .update(user.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  // Book methods
  Future<void> addBook(Book book) async {
    await _firestore.collection('books').doc(book.id).set(book.toFirestore());
  }

  Future<void> updateBook(Book book) async {
    await _firestore
        .collection('books')
        .doc(book.id)
        .update(book.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  Future<void> deleteBook(String bookId) async {
    await _firestore.collection('books').doc(bookId).delete();
  }

  Stream<List<Book>> getBooksByUser(String userId) {
    return _firestore
        .collection('books')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Book.fromFirestore(doc))
            .toList());
  }

  Stream<List<Book>> getBooksByStatus(String userId, BookStatus status) {
    return _firestore
        .collection('books')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Book.fromFirestore(doc))
            .toList());
  }

  // Note methods
  Future<void> addNote(Note note) async {
    await _firestore.collection('notes').doc(note.id).set(note.toFirestore());
  }

  Future<void> updateNote(Note note) async {
    await _firestore
        .collection('notes')
        .doc(note.id)
        .update(note.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  Future<void> deleteNote(String noteId) async {
    await _firestore.collection('notes').doc(noteId).delete();
  }

  Stream<List<Note>> getNotesByBook(String bookId) {
    return _firestore
        .collection('notes')
        .where('bookId', isEqualTo: bookId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList());
  }

  Stream<List<Note>> getNotesByUser(String userId) {
    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList());
  }

  // Flashcard methods
  Future<void> addFlashcard(Flashcard flashcard) async {
    await _firestore
        .collection('flashcards')
        .doc(flashcard.id)
        .set(flashcard.toFirestore());
  }

  Future<void> updateFlashcard(Flashcard flashcard) async {
    await _firestore
        .collection('flashcards')
        .doc(flashcard.id)
        .update(
            flashcard.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  Future<void> deleteFlashcard(String flashcardId) async {
    await _firestore.collection('flashcards').doc(flashcardId).delete();
  }

  Stream<List<Flashcard>> getDueFlashcards(String userId) {
    final now = DateTime.now();
    return _firestore
        .collection('flashcards')
        .where('userId', isEqualTo: userId)
        .where('nextReviewDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('nextReviewDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Flashcard.fromFirestore(doc))
            .toList());
  }

  Stream<List<Flashcard>> getFlashcardsByBook(String bookId) {
    return _firestore
        .collection('flashcards')
        .where('bookId', isEqualTo: bookId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Flashcard.fromFirestore(doc))
            .toList());
  }

  // Friend methods
  Future<void> addFriend(String userId, String friendId) async {
    final batch = _firestore.batch();

    // Add friend to user's friend list
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'friendIds': FieldValue.arrayUnion([friendId]),
      'updatedAt': Timestamp.now(),
    });

    // Add user to friend's friend list (bidirectional)
    final friendRef = _firestore.collection('users').doc(friendId);
    batch.update(friendRef, {
      'friendIds': FieldValue.arrayUnion([userId]),
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
  }

  Future<void> removeFriend(String userId, String friendId) async {
    final batch = _firestore.batch();

    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'friendIds': FieldValue.arrayRemove([friendId]),
      'updatedAt': Timestamp.now(),
    });

    final friendRef = _firestore.collection('users').doc(friendId);
    batch.update(friendRef, {
      'friendIds': FieldValue.arrayRemove([userId]),
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
  }

  // Storage methods for images
  Future<String> uploadImage(File file, String path, String fileName) async {
    final ref = _storage.ref().child(path).child(fileName);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> deleteImage(String url) async {
    final ref = _storage.refFromURL(url);
    await ref.delete();
  }
}


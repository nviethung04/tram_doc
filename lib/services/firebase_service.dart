import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tram_doc/models/book.dart';
import 'package:tram_doc/models/library_item.dart';
import 'package:tram_doc/models/note.dart';
import 'package:tram_doc/models/flashcard.dart';
import 'package:tram_doc/models/friendship.dart';
import 'package:tram_doc/models/activity.dart';
import 'package:tram_doc/models/user.dart' as app_user;

class FirebaseService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==================== AUTH METHODS ====================
  auth.User? get currentUser => _auth.currentUser;

  Stream<auth.User?> get authStateChanges => _auth.authStateChanges();

  Future<auth.UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<auth.UserCredential> createUserWithEmailAndPassword(
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

  // ==================== USERS COLLECTION ====================
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

  Stream<app_user.AppUser?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? app_user.AppUser.fromFirestore(doc) : null);
  }

  // ==================== BOOKS COLLECTION ====================
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

  Future<Book?> getBook(String bookId) async {
    final doc = await _firestore.collection('books').doc(bookId).get();
    if (doc.exists) {
      return Book.fromFirestore(doc);
    }
    return null;
  }

  Stream<Book?> getBookStream(String bookId) {
    return _firestore
        .collection('books')
        .doc(bookId)
        .snapshots()
        .map((doc) => doc.exists ? Book.fromFirestore(doc) : null);
  }

  // Search books by ISBN
  Future<List<Book>> searchBooksByIsbn(String isbn) async {
    final snapshot = await _firestore
        .collection('books')
        .where('isbn10', isEqualTo: isbn)
        .get();
    if (snapshot.docs.isEmpty) {
      final snapshot13 = await _firestore
          .collection('books')
          .where('isbn13', isEqualTo: isbn)
          .get();
      return snapshot13.docs.map((doc) => Book.fromFirestore(doc)).toList();
    }
    return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
  }

  // ==================== USERS/{userId}/LIBRARY SUBCOLLECTION ====================
  Future<void> addLibraryItem(String userId, LibraryItem libraryItem) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('library')
        .doc(libraryItem.id)
        .set(libraryItem.toFirestore());
  }

  Future<void> updateLibraryItem(String userId, LibraryItem libraryItem) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('library')
        .doc(libraryItem.id)
        .update(
            libraryItem.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  Future<void> deleteLibraryItem(String userId, String userBookId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('library')
        .doc(userBookId)
        .delete();
  }

  Future<LibraryItem?> getLibraryItem(String userId, String userBookId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('library')
        .doc(userBookId)
        .get();
    if (doc.exists) {
      return LibraryItem.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<LibraryItem>> getLibraryItems(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('library')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LibraryItem.fromFirestore(doc))
            .toList());
  }

  Stream<List<LibraryItem>> getLibraryItemsByStatus(
      String userId, LibraryStatus status) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('library')
        .where('status', isEqualTo: status.name)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LibraryItem.fromFirestore(doc))
            .toList());
  }

  // ==================== USERS/{userId}/NOTES SUBCOLLECTION ====================
  Future<void> addNote(String userId, Note note) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(note.id)
        .set(note.toFirestore());
  }

  Future<void> updateNote(String userId, Note note) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(note.id)
        .update(note.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  Future<void> deleteNote(String userId, String noteId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(noteId)
        .delete();
  }

  Future<Note?> getNote(String userId, String noteId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(noteId)
        .get();
    if (doc.exists) {
      return Note.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<Note>> getNotesByBook(String userId, String bookId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .where('bookId', isEqualTo: bookId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList());
  }

  Stream<List<Note>> getAllNotes(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList());
  }

  Stream<List<Note>> getKeyIdeas(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .where('isKeyIdea', isEqualTo: true)
        .orderBy('keyIdeaOrder')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList());
  }

  // ==================== USERS/{userId}/FLASHCARDS SUBCOLLECTION ====================
  Future<void> addFlashcard(String userId, Flashcard flashcard) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('flashcards')
        .doc(flashcard.id)
        .set(flashcard.toFirestore());
  }

  Future<void> updateFlashcard(String userId, Flashcard flashcard) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('flashcards')
        .doc(flashcard.id)
        .update(
            flashcard.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  Future<void> deleteFlashcard(String userId, String flashcardId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('flashcards')
        .doc(flashcardId)
        .delete();
  }

  Future<Flashcard?> getFlashcard(String userId, String flashcardId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('flashcards')
        .doc(flashcardId)
        .get();
    if (doc.exists) {
      return Flashcard.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<Flashcard>> getDueFlashcards(String userId) {
    final now = DateTime.now();
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('flashcards')
        .where('status', isEqualTo: FlashcardStatus.active.name)
        .where('dueAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('dueAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Flashcard.fromFirestore(doc))
            .toList());
  }

  Stream<List<Flashcard>> getFlashcardsByBook(String userId, String bookId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('flashcards')
        .where('bookId', isEqualTo: bookId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Flashcard.fromFirestore(doc))
            .toList());
  }

  Stream<List<Flashcard>> getAllFlashcards(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('flashcards')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Flashcard.fromFirestore(doc))
            .toList());
  }

  // ==================== FRIENDSHIPS COLLECTION ====================
  Future<String> createFriendshipRequest(
      String userId1, String userId2, String requestedBy) async {
    // Ensure consistent ordering of user IDs
    final sortedIds = [userId1, userId2]..sort();
    final friendshipId = '${sortedIds[0]}_${sortedIds[1]}';

    final friendship = Friendship(
      id: friendshipId,
      userId1: sortedIds[0],
      userId2: sortedIds[1],
      status: FriendshipStatus.pending,
      requestedBy: requestedBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('friendships')
        .doc(friendshipId)
        .set(friendship.toFirestore());

    return friendshipId;
  }

  Future<void> acceptFriendship(String friendshipId) async {
    await _firestore.collection('friendships').doc(friendshipId).update({
      'status': FriendshipStatus.accepted.name,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> blockFriendship(String friendshipId) async {
    await _firestore.collection('friendships').doc(friendshipId).update({
      'status': FriendshipStatus.blocked.name,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteFriendship(String friendshipId) async {
    await _firestore.collection('friendships').doc(friendshipId).delete();
  }

  Future<Friendship?> getFriendship(String userId1, String userId2) async {
    final sortedIds = [userId1, userId2]..sort();
    final friendshipId = '${sortedIds[0]}_${sortedIds[1]}';

    final doc =
        await _firestore.collection('friendships').doc(friendshipId).get();
    if (doc.exists) {
      return Friendship.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<Friendship>> getFriendships(String userId) {
    return _firestore
        .collection('friendships')
        .where('userId1', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Friendship.fromFirestore(doc))
            .toList());
  }

  Stream<List<Friendship>> getAcceptedFriendships(String userId) {
    return _firestore
        .collection('friendships')
        .where('userId1', isEqualTo: userId)
        .where('status', isEqualTo: FriendshipStatus.accepted.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Friendship.fromFirestore(doc))
            .toList());
  }

  // ==================== ACTIVITIES COLLECTION ====================
  Future<void> addActivity(Activity activity) async {
    await _firestore
        .collection('activities')
        .doc(activity.id)
        .set(activity.toFirestore());
  }

  Future<void> deleteActivity(String activityId) async {
    await _firestore.collection('activities').doc(activityId).delete();
  }

  Stream<List<Activity>> getActivitiesByUser(String userId) {
    return _firestore
        .collection('activities')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Activity.fromFirestore(doc))
            .toList());
  }

  Stream<List<Activity>> getPublicActivities() {
    return _firestore
        .collection('activities')
        .where('visibility', isEqualTo: ActivityVisibility.public.name)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Activity.fromFirestore(doc))
            .toList());
  }

  Stream<List<Activity>> getFriendsActivities(List<String> friendIds) {
    if (friendIds.isEmpty) {
      return Stream.value([]);
    }
    return _firestore
        .collection('activities')
        .where('userId', whereIn: friendIds)
        .where('visibility', isEqualTo: ActivityVisibility.friends.name)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Activity.fromFirestore(doc))
            .toList());
  }

  // ==================== STORAGE METHODS ====================
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

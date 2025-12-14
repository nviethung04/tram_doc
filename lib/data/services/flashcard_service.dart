import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/flashcard.dart';

class FlashcardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy reference đến collection flashcards
  CollectionReference get _flashcardsCollection =>
      _firestore.collection('flashcards');

  // Lấy userId hiện tại
  String? get _currentUserId => _auth.currentUser?.uid;

  // Lấy tất cả flashcards của user
  Future<List<Flashcard>> getAllFlashcards() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _flashcardsCollection
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Flashcard.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Error loading flashcards: $e');
    }
  }

  // Lấy flashcards theo bookId
  Future<List<Flashcard>> getFlashcardsByBook(String bookId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _flashcardsCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('bookId', isEqualTo: bookId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Flashcard.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Error loading flashcards: $e');
    }
  }

  // Lấy flashcards theo status
  Future<List<Flashcard>> getFlashcardsByStatus(FlashcardStatus status) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _flashcardsCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Flashcard.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Error loading flashcards: $e');
    }
  }

  // Lấy flashcards cần ôn hôm nay
  Future<List<Flashcard>> getDueFlashcards() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final querySnapshot = await _flashcardsCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: FlashcardStatus.due.name)
          .where('nextReviewDate', isLessThanOrEqualTo: now)
          .get();

      return querySnapshot.docs
          .map((doc) => Flashcard.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      // Fallback: get all due flashcards if query fails (might need index)
      return getFlashcardsByStatus(FlashcardStatus.due);
    }
  }

  // Lấy chi tiết một flashcard
  Future<Flashcard> getFlashcardById(String flashcardId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final docSnapshot = await _flashcardsCollection.doc(flashcardId).get();

      if (!docSnapshot.exists) {
        throw Exception('Flashcard not found');
      }

      final data = docSnapshot.data() as Map<String, dynamic>;

      // Kiểm tra quyền sở hữu
      if (data['userId'] != _currentUserId) {
        throw Exception('Unauthorized access');
      }

      return Flashcard.fromFirestore(data, docSnapshot.id);
    } catch (e) {
      throw Exception('Error loading flashcard: $e');
    }
  }

  // Tạo flashcard mới
  Future<Flashcard> createFlashcard(Flashcard flashcard) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Tạo flashcard với userId hiện tại
      final flashcardData = flashcard.copyWith(
        userId: _currentUserId!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _flashcardsCollection.add(flashcardData.toFirestore());

      // Lấy document vừa tạo để trả về với ID chính xác
      final docSnapshot = await docRef.get();
      return Flashcard.fromFirestore(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
    } catch (e) {
      throw Exception('Error creating flashcard: $e');
    }
  }

  // Tạo flashcard từ note
  Future<Flashcard> createFlashcardFromNote({
    required String noteId,
    required String bookId,
    required String bookTitle,
    required String question,
    required String answer,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final flashcard = Flashcard(
        id: '',
        userId: _currentUserId!,
        bookId: bookId,
        bookTitle: bookTitle,
        noteId: noteId,
        question: question,
        answer: answer,
        timesReviewed: 0,
        status: FlashcardStatus.due,
        level: 'Easy',
        nextReviewDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await createFlashcard(flashcard);
    } catch (e) {
      throw Exception('Error creating flashcard from note: $e');
    }
  }

  // Cập nhật flashcard
  Future<void> updateFlashcard(String flashcardId, Flashcard updatedFlashcard) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Kiểm tra quyền sở hữu trước khi cập nhật
      final docSnapshot = await _flashcardsCollection.doc(flashcardId).get();
      if (!docSnapshot.exists) {
        throw Exception('Flashcard not found');
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      if (data['userId'] != _currentUserId) {
        throw Exception('Unauthorized access');
      }

      // Cập nhật flashcard
      final updateData = updatedFlashcard.copyWith(
        updatedAt: DateTime.now(),
      ).toFirestore();

      await _flashcardsCollection.doc(flashcardId).update(updateData);
    } catch (e) {
      throw Exception('Error updating flashcard: $e');
    }
  }

  // Đánh dấu flashcard đã ôn (với spaced repetition)
  Future<void> markAsReviewed({
    required String flashcardId,
    required String difficulty, // 'easy', 'medium', 'hard'
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final flashcard = await getFlashcardById(flashcardId);

      // Tính ngày ôn tiếp theo dựa trên độ khó
      DateTime nextReview;
      switch (difficulty.toLowerCase()) {
        case 'easy':
          nextReview = DateTime.now().add(const Duration(days: 7));
          break;
        case 'medium':
          nextReview = DateTime.now().add(const Duration(days: 3));
          break;
        case 'hard':
          nextReview = DateTime.now().add(const Duration(days: 1));
          break;
        default:
          nextReview = DateTime.now().add(const Duration(days: 3));
      }

      final updatedFlashcard = flashcard.copyWith(
        timesReviewed: flashcard.timesReviewed + 1,
        level: difficulty,
        nextReviewDate: nextReview,
        status: FlashcardStatus.done,
      );

      await updateFlashcard(flashcardId, updatedFlashcard);
    } catch (e) {
      throw Exception('Error marking flashcard as reviewed: $e');
    }
  }

  // Đánh dấu flashcard để ôn sau
  Future<void> markAsLater(String flashcardId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final flashcard = await getFlashcardById(flashcardId);
      final updatedFlashcard = flashcard.copyWith(
        status: FlashcardStatus.later,
        nextReviewDate: DateTime.now().add(const Duration(days: 7)),
      );

      await updateFlashcard(flashcardId, updatedFlashcard);
    } catch (e) {
      throw Exception('Error marking flashcard as later: $e');
    }
  }

  // Xóa flashcard
  Future<void> deleteFlashcard(String flashcardId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Kiểm tra quyền sở hữu trước khi xóa
      final docSnapshot = await _flashcardsCollection.doc(flashcardId).get();
      if (!docSnapshot.exists) {
        throw Exception('Flashcard not found');
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      if (data['userId'] != _currentUserId) {
        throw Exception('Unauthorized access');
      }

      await _flashcardsCollection.doc(flashcardId).delete();
    } catch (e) {
      throw Exception('Error deleting flashcard: $e');
    }
  }

  // Lấy thống kê flashcards
  Future<Map<String, int>> getFlashcardStats() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final allFlashcards = await getAllFlashcards();

      final dueCount = allFlashcards.where((f) => f.status == FlashcardStatus.due).length;
      final doneCount = allFlashcards.where((f) => f.status == FlashcardStatus.done).length;
      final laterCount = allFlashcards.where((f) => f.status == FlashcardStatus.later).length;

      return {
        'total': allFlashcards.length,
        'due': dueCount,
        'done': doneCount,
        'later': laterCount,
      };
    } catch (e) {
      throw Exception('Error getting flashcard stats: $e');
    }
  }

  // Stream để lắng nghe thay đổi theo thời gian thực
  Stream<List<Flashcard>> streamFlashcards() {
    if (_currentUserId == null) {
      return Stream.error('User not authenticated');
    }

    return _flashcardsCollection
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Flashcard.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  // Stream flashcards theo bookId
  Stream<List<Flashcard>> streamFlashcardsByBook(String bookId) {
    if (_currentUserId == null) {
      return Stream.error('User not authenticated');
    }

    return _flashcardsCollection
        .where('userId', isEqualTo: _currentUserId)
        .where('bookId', isEqualTo: bookId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Flashcard.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }
}

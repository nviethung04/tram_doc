import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/library_item.dart';
import 'base_firestore_service.dart';

class LibraryService extends BaseFirestoreService {
  LibraryService({super.firestore, super.auth});

  CollectionReference get _libraryCollection => collection('library');

  /// Thêm sách vào thư viện
  Future<LibraryItem> addToLibrary({
    required String bookId,
    bool isPublic = false,
  }) async {
    requireAuth();
    try {
      final now = DateTime.now();
      final libraryItem = LibraryItem(
        id: '',
        userId: currentUserId!,
        bookId: bookId,
        isPublic: isPublic,
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _libraryCollection.add(libraryItem.toFirestore());
      final docSnapshot = await docRef.get();
      return LibraryItem.fromFirestore(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
    } catch (e) {
      throw Exception('Error adding to library: $e');
    }
  }

  /// Xóa sách khỏi thư viện
  Future<void> removeFromLibrary(String libraryId) async {
    requireAuth();
    try {
      final doc = await _libraryCollection.doc(libraryId).get();
      if (!doc.exists) {
        throw Exception('Library item not found');
      }
      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != currentUserId) {
        throw Exception('Unauthorized');
      }
      await _libraryCollection.doc(libraryId).delete();
    } catch (e) {
      throw Exception('Error removing from library: $e');
    }
  }

  /// Lấy tất cả sách trong thư viện của user
  Future<List<LibraryItem>> getMyLibrary() async {
    requireAuth();
    try {
      final querySnapshot = await _libraryCollection
          .where('userId', isEqualTo: currentUserId)
          .orderBy('addedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => LibraryItem.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Error getting library: $e');
    }
  }

  /// Lấy thư viện công khai (của bạn bè)
  Future<List<LibraryItem>> getPublicLibrary() async {
    requireAuth();
    try {
      final querySnapshot = await _libraryCollection
          .where('isPublic', isEqualTo: true)
          .orderBy('addedAt', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs
          .map((doc) => LibraryItem.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Error getting public library: $e');
    }
  }

  /// Kiểm tra sách đã có trong thư viện chưa
  Future<bool> isInLibrary(String bookId) async {
    requireAuth();
    try {
      final querySnapshot = await _libraryCollection
          .where('userId', isEqualTo: currentUserId)
          .where('bookId', isEqualTo: bookId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}


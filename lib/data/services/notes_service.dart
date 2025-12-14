import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/note.dart';

class NotesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy reference đến collection notes
  CollectionReference get _notesCollection => _firestore.collection('notes');

  // Lấy userId hiện tại
  String? get _currentUserId => _auth.currentUser?.uid;

  // Lấy tất cả notes của một cuốn sách (của user hiện tại)
  Future<List<Note>> getNotesByBook(String bookId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _notesCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('bookId', isEqualTo: bookId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) =>
                Note.fromFirestore(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      throw Exception('Error loading notes: $e');
    }
  }

  // Lấy chi tiết một note
  Future<Note> getNoteById(String noteId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final docSnapshot = await _notesCollection.doc(noteId).get();

      if (!docSnapshot.exists) {
        throw Exception('Note not found');
      }

      final data = docSnapshot.data() as Map<String, dynamic>;

      // Kiểm tra quyền sở hữu
      if (data['userId'] != _currentUserId) {
        throw Exception('Unauthorized access');
      }

      return Note.fromFirestore(data, docSnapshot.id);
    } catch (e) {
      throw Exception('Error loading note: $e');
    }
  }

  // Tạo note mới
  Future<Note> createNote(Note note) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Tạo note với userId hiện tại
      final noteData = note.copyWith(
        userId: _currentUserId!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _notesCollection.add(noteData.toFirestore());

      // Lấy document vừa tạo để trả về với ID chính xác
      final docSnapshot = await docRef.get();
      return Note.fromFirestore(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
    } catch (e) {
      throw Exception('Error creating note: $e');
    }
  }

  // Cập nhật note
  Future<void> updateNote(String noteId, Note updatedNote) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Kiểm tra quyền sở hữu trước khi cập nhật
      final docSnapshot = await _notesCollection.doc(noteId).get();
      if (!docSnapshot.exists) {
        throw Exception('Note not found');
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      if (data['userId'] != _currentUserId) {
        throw Exception('Unauthorized access');
      }

      // Cập nhật note
      final updateData = updatedNote
          .copyWith(updatedAt: DateTime.now())
          .toFirestore();

      await _notesCollection.doc(noteId).update(updateData);
    } catch (e) {
      throw Exception('Error updating note: $e');
    }
  }

  // Xóa note
  Future<void> deleteNote(String noteId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Kiểm tra quyền sở hữu trước khi xóa
      final docSnapshot = await _notesCollection.doc(noteId).get();
      if (!docSnapshot.exists) {
        throw Exception('Note not found');
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      if (data['userId'] != _currentUserId) {
        throw Exception('Unauthorized access');
      }

      await _notesCollection.doc(noteId).delete();
    } catch (e) {
      throw Exception('Error deleting note: $e');
    }
  }

  // Lấy tất cả key ideas của một cuốn sách
  Future<List<Note>> getKeyIdeasByBook(String bookId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _notesCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('bookId', isEqualTo: bookId)
          .where('isKeyIdea', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) =>
                Note.fromFirestore(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      throw Exception('Error loading key ideas: $e');
    }
  }

  // Stream để lắng nghe thay đổi theo thời gian thực
  Stream<List<Note>> streamNotesByBook(String bookId) {
    if (_currentUserId == null) {
      return Stream.error('User not authenticated');
    }

    return _notesCollection
        .where('userId', isEqualTo: _currentUserId)
        .where('bookId', isEqualTo: bookId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Note.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }
}

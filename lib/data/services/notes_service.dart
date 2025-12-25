import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/note.dart';
import 'ocr_service.dart';

class NotesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy reference đến collection notes
  CollectionReference get _notesCollection => _firestore.collection('notes');

  // Lấy userId hiện tại
  String? get _currentUserId => _auth.currentUser?.uid;

  // Lấy tất cả notes của user hiện tại (across all books)
  Future<List<Note>> getAllNotes() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _notesCollection
          .where('userId', isEqualTo: _currentUserId)
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

  /// Upload ảnh lên Firebase Storage và trả về URL
  Future<String> uploadImage(Uint8List imageBytes, String noteId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final storage = FirebaseStorage.instance;
      final ref = storage
          .ref()
          .child('notes')
          .child(_currentUserId!)
          .child('$noteId.jpg');

      // Upload với metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'noteId': noteId,
          'userId': _currentUserId!,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putData(
        imageBytes,
        metadata,
      );

      // Đợi upload hoàn thành
      final snapshot = await uploadTask;
      
      // Lấy download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found' || e.code == 'unauthorized') {
        throw Exception('Không thể upload ảnh. Vui lòng kiểm tra cấu hình Firebase Storage.');
      }
      throw Exception('Lỗi upload ảnh: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi upload ảnh: $e');
    }
  }

  /// Tạo note từ ảnh với OCR
  /// Upload ảnh → OCR → lưu text và ảnh URL
  Future<Note> createNoteFromImage({
    required String bookId,
    required String bookTitle,
    required Uint8List imageBytes,
    int? page,
    bool isKeyIdea = false,
    String language = 'vie',
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();

      // Tạo note tạm để có ID
      final tempNote = Note(
        id: '', // Sẽ được tạo bởi Firestore
        userId: _currentUserId!,
        bookId: bookId,
        bookTitle: bookTitle,
        content: '', // Sẽ được cập nhật sau khi OCR
        page: page,
        isKeyIdea: isKeyIdea,
        createdAt: now,
        updatedAt: now,
      );

      // Tạo note trong Firestore để có ID
      final docRef = await _notesCollection.add(tempNote.toFirestore());
      final noteId = docRef.id;

      // Upload ảnh lên Storage
      final imageUrl = await uploadImage(imageBytes, noteId);

      // OCR để extract text (sử dụng Cloud Functions với OCR.space)
      final ocrService = OCRService();
      final ocrResult = await ocrService.extractTextFromImage(
        imageBytes,
        language: language,
      );
      final ocrText = ocrResult['text'] as String? ?? '';

      // Tạo note với OCR text
      final note = tempNote.copyWith(
        id: noteId,
        content: ocrText.isNotEmpty ? ocrText : 'Không thể đọc text từ ảnh',
        imageUrl: imageUrl,
        ocrText: ocrText,
      );

      // Cập nhật note với OCR result
      await _notesCollection.doc(noteId).update(note.toFirestore());

      return note;
    } catch (e) {
      throw Exception('Error creating note from image: $e');
    }
  }

  /// Extract key ideas từ note (3-5 ý chính)
  Future<List<String>> extractKeyIdeasFromNote(String noteId) async {
    try {
      final note = await getNoteById(noteId);
      final text = note.ocrText ?? note.content;
      final ocrService = OCRService();
      return await ocrService.extractKeyIdeas(text);
    } catch (e) {
      throw Exception('Error extracting key ideas: $e');
    }
  }

  /// Đánh dấu note là Key Idea
  Future<void> markAsKeyIdea(String noteId) async {
    try {
      final note = await getNoteById(noteId);
      final updatedNote = note.copyWith(isKeyIdea: true);
      await updateNote(noteId, updatedNote);
    } catch (e) {
      throw Exception('Error marking note as key idea: $e');
    }
  }

  /// Lấy tất cả Key Ideas của user
  Future<List<Note>> getAllKeyIdeas() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _notesCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('isKeyIdea', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => Note.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Error loading key ideas: $e');
    }
  }
}

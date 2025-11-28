import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class NoteProvider extends ChangeNotifier {
  List<Note> _notes = [];
  List<Note> _reviewNotes = [];

  bool _isLoading = false;
  String? _error;

  List<Note> get notes => _notes;
  List<Note> get reviewNotes => _reviewNotes;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchNotes({int? bookId, NoteType? type, String? search}) async {
    try {
      setLoading(true);
      clearError();

      final fetchedNotes = await ApiService.getNotes(
        bookId: bookId,
        type: type,
        search: search,
      );

      _notes = fetchedNotes;
      setLoading(false);
    } catch (e) {
      setError(e.toString());
      setLoading(false);
    }
  }

  Future<bool> addNote({
    required int bookId,
    required String content,
    int? page,
    NoteType? type,
  }) async {
    try {
      setLoading(true);
      clearError();

      final newNote = await ApiService.createNote(
        bookId: bookId,
        content: content,
        page: page,
        type: type,
      );

      _notes.insert(0, newNote); // Add to beginning for chronological order
      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  Future<bool> updateNote(int noteId, Map<String, dynamic> updates) async {
    try {
      setLoading(true);
      clearError();

      final updatedNote = await ApiService.updateNote(noteId, updates);

      final index = _notes.indexWhere((note) => note.id == noteId);
      if (index != -1) {
        _notes[index] = updatedNote;
      }

      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  Future<bool> deleteNote(int noteId) async {
    try {
      setLoading(true);
      clearError();

      await ApiService.deleteNote(noteId);

      _notes.removeWhere((note) => note.id == noteId);
      _reviewNotes.removeWhere((note) => note.id == noteId);

      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  Future<bool> createFlashcard(int noteId) async {
    try {
      clearError();

      await ApiService.createFlashcard(noteId);

      // Update the note in local list
      final index = _notes.indexWhere((note) => note.id == noteId);
      if (index != -1) {
        // Note: This is a simplified update. In a real app, you'd want to fetch the updated note
        // or update the local note with the new flashcard properties
        notifyListeners();
      }

      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  Future<void> fetchReviewNotes() async {
    try {
      setLoading(true);
      clearError();

      final fetchedReviewNotes = await ApiService.getReviewNotes();

      _reviewNotes = fetchedReviewNotes;
      setLoading(false);
    } catch (e) {
      setError(e.toString());
      setLoading(false);
    }
  }

  Future<bool> reviewFlashcard(int noteId, int quality) async {
    try {
      clearError();

      // This would need to be implemented in the API service
      // await ApiService.reviewFlashcard(noteId, quality);

      // Remove from review list if successfully reviewed
      _reviewNotes.removeWhere((note) => note.id == noteId);
      notifyListeners();

      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  List<Note> getNotesForBook(int bookId) {
    return _notes.where((note) => note.bookId == bookId).toList();
  }

  List<Note> getNotesByType(NoteType type) {
    return _notes.where((note) => note.type == type).toList();
  }

  List<Note> getFlashcards() {
    return _notes.where((note) => note.isFlashcard).toList();
  }

  Note? getNoteById(int noteId) {
    try {
      return _notes.firstWhere((note) => note.id == noteId);
    } catch (e) {
      return null;
    }
  }

  // Statistics
  int get totalNotes => _notes.length;
  int get totalFlashcards => getFlashcards().length;
  int get notesReview => _reviewNotes.length;

  Map<NoteType, int> get notesByType {
    final map = <NoteType, int>{};
    for (final type in NoteType.values) {
      map[type] = getNotesByType(type).length;
    }
    return map;
  }

  // Search functionality
  List<Note> searchNotes(String query) {
    if (query.isEmpty) return _notes;

    return _notes.where((note) {
      return note.content.toLowerCase().contains(query.toLowerCase()) ||
          note.book?.title.toLowerCase().contains(query.toLowerCase()) == true;
    }).toList();
  }
}

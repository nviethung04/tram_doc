import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';

  static String? _token;

  // Headers with authentication
  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // Initialize token from storage
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // Save token to storage
  static Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear token
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Check if user is authenticated
  static bool get isAuthenticated => _token != null;

  // Handle API errors
  static String _handleError(http.Response response) {
    try {
      final data = json.decode(response.body);
      return data['error'] ?? 'Unknown error occurred';
    } catch (e) {
      return 'Server error: ${response.statusCode}';
    }
  }

  // Authentication APIs
  static Future<AuthResponse> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: json.encode({
        'email': email,
        'username': username,
        'password': password,
        'full_name': fullName,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      final authResponse = AuthResponse.fromJson(data);
      await _saveToken(authResponse.token);
      return authResponse;
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final authResponse = AuthResponse.fromJson(data);
      await _saveToken(authResponse.token);
      return authResponse;
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<void> logout() async {
    await http.post(Uri.parse('$baseUrl/auth/logout'), headers: _headers);
    await clearToken();
  }

  // Books APIs
  static Future<List<Book>> getBooks({
    BookStatus? status,
    String? search,
  }) async {
    var url = '$baseUrl/books';
    var queryParams = <String, String>{};

    if (status != null) queryParams['status'] = status.value;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    if (queryParams.isNotEmpty) {
      url +=
          '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    }

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final books = (data['books'] as List)
          .map((book) => Book.fromJson(book))
          .toList();
      return books;
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<Book> createBook({
    required String title,
    String? authors,
    String? isbn,
    String? googleId,
    String? publisher,
    String? publishDate,
    String? description,
    String? coverUrl,
    int? pageCount,
    BookStatus? status,
    String? location,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/books'),
      headers: _headers,
      body: json.encode({
        'title': title,
        'authors': authors,
        'isbn': isbn,
        'google_id': googleId,
        'publisher': publisher,
        'publish_date': publishDate,
        'description': description,
        'cover_url': coverUrl,
        'page_count': pageCount,
        'status': status?.value ?? BookStatus.wantToRead.value,
        'location': location,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return Book.fromJson(data);
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<Book> updateBook(
    int bookId,
    Map<String, dynamic> updates,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/books/$bookId'),
      headers: _headers,
      body: json.encode(updates),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Book.fromJson(data);
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<void> deleteBook(int bookId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/books/$bookId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_handleError(response));
    }
  }

  static Future<List<Map<String, dynamic>>> searchBooks(String query) async {
    final response = await http.post(
      Uri.parse('$baseUrl/books/search'),
      headers: _headers,
      body: json.encode({'query': query}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['results']);
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<Map<String, dynamic>> scanBarcode(String barcode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/books/barcode'),
      headers: _headers,
      body: json.encode({'barcode': barcode}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['book'];
    } else {
      throw Exception(_handleError(response));
    }
  }

  // Notes APIs
  static Future<List<Note>> getNotes({
    int? bookId,
    NoteType? type,
    String? search,
  }) async {
    var url = '$baseUrl/notes';
    var queryParams = <String, String>{};

    if (bookId != null) queryParams['book_id'] = bookId.toString();
    if (type != null) queryParams['type'] = type.value;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    if (queryParams.isNotEmpty) {
      url +=
          '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    }

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final notes = (data['notes'] as List)
          .map((note) => Note.fromJson(note))
          .toList();
      return notes;
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<Note> createNote({
    required int bookId,
    required String content,
    int? page,
    NoteType? type,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notes'),
      headers: _headers,
      body: json.encode({
        'book_id': bookId,
        'content': content,
        'page': page,
        'type': type?.value ?? NoteType.note.value,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return Note.fromJson(data);
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<Note> updateNote(
    int noteId,
    Map<String, dynamic> updates,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notes/$noteId'),
      headers: _headers,
      body: json.encode(updates),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Note.fromJson(data);
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<void> deleteNote(int noteId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/notes/$noteId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_handleError(response));
    }
  }

  static Future<void> createFlashcard(int noteId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notes/flashcard'),
      headers: _headers,
      body: json.encode({'note_id': noteId}),
    );

    if (response.statusCode != 200) {
      throw Exception(_handleError(response));
    }
  }

  static Future<List<Note>> getReviewNotes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notes/review'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final notes = (data['notes'] as List)
          .map((note) => Note.fromJson(note))
          .toList();
      return notes;
    } else {
      throw Exception(_handleError(response));
    }
  }

  // Social APIs
  static Future<List<User>> getFriends() async {
    final response = await http.get(
      Uri.parse('$baseUrl/social/friends'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final friends = (data['friends'] as List)
          .map((friend) => User.fromJson(friend))
          .toList();
      return friends;
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<void> addFriend(String friendEmail) async {
    final response = await http.post(
      Uri.parse('$baseUrl/social/friends/add'),
      headers: _headers,
      body: json.encode({'friend_email': friendEmail}),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(_handleError(response));
    }
  }

  static Future<void> removeFriend(int friendId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/social/friends/$friendId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_handleError(response));
    }
  }

  static Future<List<Activity>> getFeed({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/social/feed?limit=$limit&offset=$offset'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final activities = (data['activities'] as List)
          .map((activity) => Activity.fromJson(activity))
          .toList();
      return activities;
    } else {
      throw Exception(_handleError(response));
    }
  }
}

class AuthResponse {
  final User user;
  final String token;

  AuthResponse({required this.user, required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user']),
      token: json['token'],
    );
  }
}

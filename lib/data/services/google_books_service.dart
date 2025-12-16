import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/book.dart';

/// Service gọi Google Books API để tìm kiếm và tra ISBN.
class GoogleBooksService {
  GoogleBooksService({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _apiKey = (apiKey ?? _envKey).isEmpty ? null : (apiKey ?? _envKey);

  static const _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  /// Lấy API key từ --dart-define nếu có, tránh hardcode.
  static const _envKey = String.fromEnvironment('GOOGLE_BOOKS_API_KEY', defaultValue: '');

  final http.Client _client;
  final String? _apiKey;

  Future<List<Book>> searchBooks(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse(
      '$_baseUrl?q=${Uri.encodeQueryComponent(query)}&maxResults=20&printType=books${_apiKey != null ? '&key=$_apiKey' : ''}',
    );
    final resp = await _client.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Google Books error ${resp.statusCode}');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final items = (json['items'] as List?) ?? const [];
    return items
        .map<Book?>((e) => Book.fromGoogleVolume(e as Map<String, dynamic>))
        .whereType<Book>()
        .toList();
  }

  Future<Book?> lookupIsbn(String isbn) async {
    final uri = Uri.parse(
      '$_baseUrl?q=isbn:${Uri.encodeQueryComponent(isbn)}${_apiKey != null ? '&key=$_apiKey' : ''}',
    );
    final resp = await _client.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Google Books error ${resp.statusCode}');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final items = (json['items'] as List?) ?? const [];
    if (items.isEmpty) return null;
    return Book.fromGoogleVolume(items.first as Map<String, dynamic>);
  }
}

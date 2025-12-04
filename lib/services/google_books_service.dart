import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GoogleBooksService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  Future<List<Map<String, dynamic>>> searchBooks(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?q=${Uri.encodeComponent(query)}&maxResults=20'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List?;
        if (items != null) {
          return items.map((item) {
            final volumeInfo = item['volumeInfo'] as Map<String, dynamic>;
            return {
              'id': item['id'],
              'title': volumeInfo['title'] ?? '',
              'author': (volumeInfo['authors'] as List?)?.join(', ') ?? '',
              'description': volumeInfo['description'] ?? '',
              'isbn': _extractISBN(volumeInfo['industryIdentifiers']),
              'coverUrl': volumeInfo['imageLinks']?['thumbnail']?.replaceAll(
                    'http://',
                    'https://',
                  ) ??
                  '',
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error searching books: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getBookByISBN(String isbn) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?q=isbn:$isbn'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List?;
        if (items != null && items.isNotEmpty) {
          final item = items[0];
          final volumeInfo = item['volumeInfo'] as Map<String, dynamic>;
          return {
            'id': item['id'],
            'title': volumeInfo['title'] ?? '',
            'author': (volumeInfo['authors'] as List?)?.join(', ') ?? '',
            'description': volumeInfo['description'] ?? '',
            'isbn': _extractISBN(volumeInfo['industryIdentifiers']),
            'coverUrl': volumeInfo['imageLinks']?['thumbnail']?.replaceAll(
                  'http://',
                  'https://',
                ) ??
                '',
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting book by ISBN: $e');
      return null;
    }
  }

  String? _extractISBN(dynamic identifiers) {
    if (identifiers == null) return null;
    final list = identifiers as List;
    for (var identifier in list) {
      final type = identifier['type'] as String?;
      if (type == 'ISBN_13' || type == 'ISBN_10') {
        return identifier['identifier'] as String?;
      }
    }
    return null;
  }
}


import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service xử lý OCR (Optical Character Recognition)
/// Sử dụng Firebase Cloud Functions để đảm bảo bảo mật API key
/// Client không cần biết API key, chỉ gọi HTTPS endpoint
class OCRService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-southeast1', // Match Cloud Function region
  );

  /// Extract text từ ảnh sử dụng Firebase Cloud Functions
  /// API key được giữ an toàn trên server
  ///
  /// [imageBytes]: Bytes của ảnh cần OCR
  /// [languageHints]: Mảng các ngôn ngữ (ví dụ: ['vi', 'en'])
  /// Returns: Map với 'text' và 'confidence'
  Future<Map<String, dynamic>> extractTextFromImage(
    Uint8List imageBytes, {
    List<String>? languageHints,
  }) async {
    try {
      // Encode ảnh sang base64
      final base64Image = base64Encode(imageBytes);

      // Gọi Cloud Function với OCR.space
      final callable = _functions.httpsCallable('performOCR');
      final result = await callable.call({
        'imageBase64': base64Image,
        'language': languageHints?.isNotEmpty == true
            ? (languageHints!.first == 'vi' ? 'vie' : 'eng')
            : 'vie', // Default to Vietnamese
      });

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return {
          'success': true,
          'text': data['text'] as String? ?? '',
          'confidence': data['confidence'] as double? ?? 0.0,
        };
      } else {
        throw Exception(data['error'] as String? ?? 'OCR failed');
      }
    } catch (e) {
      print('OCR Error: $e');
      rethrow;
    }
  }

  /// Extract text từ ảnh URL (nếu ảnh đã upload lên storage)
  /// Download ảnh trước, sau đó gọi OCR
  Future<Map<String, dynamic>> extractTextFromImageUrl(
    String imageUrl, {
    List<String>? languageHints,
  }) async {
    try {
      // Download ảnh từ URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return await extractTextFromImage(
          response.bodyBytes,
          languageHints: languageHints,
        );
      } else {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      print('OCR from URL Error: $e');
      rethrow;
    }
  }

  /// Extract key ideas từ text sử dụng Cloud Function
  /// Sử dụng thuật toán cải tiến thay vì simple heuristics
  Future<List<String>> extractKeyIdeas(String text, {int maxIdeas = 5}) async {
    try {
      if (text.trim().isEmpty) return [];

      final callable = _functions.httpsCallable('extractKeyIdeas');
      final result = await callable.call({'text': text, 'maxIdeas': maxIdeas});

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final ideas = data['ideas'] as List<dynamic>?;
        return ideas?.map((e) => e.toString()).toList() ?? [];
      } else {
        // Fallback to local extraction if Cloud Function fails
        return _extractKeyIdeasLocal(text, maxIdeas);
      }
    } catch (e) {
      print('Key Ideas Extraction Error: $e');
      // Fallback to local extraction
      return _extractKeyIdeasLocal(text, maxIdeas);
    }
  }

  /// Local fallback for key ideas extraction
  /// Used when Cloud Function is unavailable
  List<String> _extractKeyIdeasLocal(String text, int maxIdeas) {
    if (text.isEmpty) return [];

    // Split into sentences
    final sentences = text
        .split(RegExp(r'[.!?]\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 20)
        .toList();

    if (sentences.isEmpty) return [];

    // Score sentences
    final scored = sentences.asMap().entries.map((entry) {
      final index = entry.key;
      final sentence = entry.value;
      double score = 0;

      // Length score
      score += (sentence.length / 100).clamp(0, 1.5) * 0.3;

      // Position score
      final positionRatio = index / sentences.length;
      if (positionRatio < 0.2 || positionRatio > 0.8) {
        score += 0.2;
      }

      // Question mark
      if (sentence.contains('?')) {
        score += 0.3;
      }

      // Numbered/bulleted
      if (RegExp(r'^[\d\-\*•]\s').hasMatch(sentence) ||
          RegExp(r'^\d+[\.\)]\s').hasMatch(sentence)) {
        score += 0.4;
      }

      return {'text': sentence, 'score': score, 'index': index};
    }).toList();

    // Sort by score
    scored.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );

    // Take top N
    return scored.take(maxIdeas).map((e) => e['text'] as String).toList();
  }
}

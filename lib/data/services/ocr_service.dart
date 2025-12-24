import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service xử lý OCR (Optical Character Recognition)
/// Hiện tại sử dụng Google Cloud Vision API
/// Có thể thay đổi implementation sau để dùng package khác
class OCRService {
  // TODO: Thêm API key vào environment variables
  static const String _apiKey = 'YOUR_GOOGLE_CLOUD_VISION_API_KEY';
  static const String _apiUrl = 'https://vision.googleapis.com/v1/images:annotate?key=$_apiKey';

  /// Extract text từ ảnh sử dụng Google Cloud Vision API
  /// 
  /// [imageBytes]: Bytes của ảnh cần OCR
  /// Returns: Text được extract từ ảnh
  static Future<String> extractTextFromImage(Uint8List imageBytes) async {
    try {
      // Encode ảnh sang base64
      final base64Image = base64Encode(imageBytes);

      // Tạo request body
      final requestBody = {
        'requests': [
          {
            'image': {
              'content': base64Image,
            },
            'features': [
              {
                'type': 'TEXT_DETECTION',
                'maxResults': 10,
              }
            ],
          }
        ],
      };

      // Gửi request đến Google Cloud Vision API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final textAnnotations = data['responses'][0]['textAnnotations'] as List?;
        
        if (textAnnotations != null && textAnnotations.isNotEmpty) {
          // Lấy full text annotation (phần tử đầu tiên chứa toàn bộ text)
          return textAnnotations[0]['description'] as String? ?? '';
        }
        return '';
      } else {
        throw Exception('OCR API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Fallback: trả về empty string nếu OCR fail
      // Có thể log error để debug
      print('OCR Error: $e');
      return '';
    }
  }

  /// Extract text từ ảnh URL (nếu ảnh đã upload lên storage)
  static Future<String> extractTextFromImageUrl(String imageUrl) async {
    try {
      // Download ảnh từ URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return await extractTextFromImage(response.bodyBytes);
      } else {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      print('OCR from URL Error: $e');
      return '';
    }
  }

  /// Extract key ideas từ text (3-5 ý chính)
  /// Sử dụng simple heuristic: tách theo câu và lấy các câu dài nhất
  static List<String> extractKeyIdeas(String text, {int maxIdeas = 5}) {
    if (text.isEmpty) return [];

    // Tách text thành các câu
    final sentences = text
        .split(RegExp(r'[.!?]\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 20) // Chỉ lấy câu dài hơn 20 ký tự
        .toList();

    // Sắp xếp theo độ dài (câu dài hơn thường là ý chính)
    sentences.sort((a, b) => b.length.compareTo(a.length));

    // Lấy top N câu
    return sentences.take(maxIdeas).toList();
  }
}


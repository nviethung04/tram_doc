import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Chọn ảnh từ gallery hoặc camera
  static Future<Uint8List?> pickAndProcessImage({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 512,
    int maxHeight = 512,
    int quality = 85,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: quality,
      );

      if (pickedFile == null) return null;

      // Đọc file ảnh
      final Uint8List imageBytes = await pickedFile.readAsBytes();

      // Decode và resize ảnh
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;

      // Resize ảnh nếu quá lớn
      img.Image resizedImage = originalImage;
      if (originalImage.width > maxWidth || originalImage.height > maxHeight) {
        resizedImage = img.copyResize(
          originalImage,
          width: maxWidth,
          height: maxHeight,
          maintainAspect: true,
        );
      }

      // Encode lại thành JPEG với quality
      final Uint8List compressedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: quality),
      );

      return compressedBytes;
    } catch (e) {
      debugPrint('Error picking/processing image: $e');
      return null;
    }
  }

  /// Convert ảnh bytes sang base64 data URI
  static String bytesToDataUri(Uint8List imageBytes, {String format = 'jpeg'}) {
    final String base64String = base64Encode(imageBytes);
    return 'data:image/$format;base64,$base64String';
  }

  /// Kiểm tra xem string có phải là data URI không
  static bool isDataUri(String? uri) {
    return uri != null && uri.startsWith('data:image/');
  }

  /// Kiểm tra xem string có phải là URL không
  static bool isUrl(String? uri) {
    return uri != null &&
        (uri.startsWith('http://') || uri.startsWith('https://'));
  }

  /// Lấy ImageProvider từ photoUrl (hỗ trợ cả data URI và URL)
  static ImageProvider? getImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;

    if (isDataUri(photoUrl)) {
      // Decode base64 từ data URI
      final String base64String = photoUrl.split(',')[1];
      final Uint8List bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } else if (isUrl(photoUrl)) {
      return NetworkImage(photoUrl);
    }

    return null;
  }
}

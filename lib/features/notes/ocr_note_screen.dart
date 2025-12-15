import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class OCRNoteScreen extends StatefulWidget {
  final Book book;

  const OCRNoteScreen({super.key, required this.book});

  @override
  State<OCRNoteScreen> createState() => _OCRNoteScreenState();
}

class _OCRNoteScreenState extends State<OCRNoteScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chụp ảnh ghi chú (OCR)')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 100,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Chức năng OCR',
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Tính năng chụp ảnh và chuyển đổi văn bản (OCR) sẽ được triển khai trong giai đoạn tiếp theo.',
                style: AppTypography.body.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Chức năng dự kiến:',
                          style: AppTypography.bodyBold.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _FeatureItem(text: 'Chụp ảnh / chọn từ thư viện'),
                    _FeatureItem(text: 'Nhận dạng văn bản (OCR)'),
                    _FeatureItem(text: 'Chỉnh sửa text nhận dạng'),
                    _FeatureItem(text: 'Lưu làm ghi chú'),
                    _FeatureItem(text: 'Tạo flashcard trực tiếp'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: AppTypography.body)),
        ],
      ),
    );
  }
}

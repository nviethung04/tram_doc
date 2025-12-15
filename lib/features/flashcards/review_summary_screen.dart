import 'package:flutter/material.dart';
import '../../components/app_button.dart';

class ReviewSummaryScreen extends StatelessWidget {
  final int total;
  final int remembered;
  final int forgotten;
  const ReviewSummaryScreen({
    super.key,
    required this.total,
    required this.remembered,
    required this.forgotten,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tổng kết')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn đã ôn $total flashcard'),
            const SizedBox(height: 8),
            Text('Nhớ rõ: $remembered'),
            Text('Quên: $forgotten'),
            const SizedBox(height: 16),
            Text('Ngày mai chúng ta sẽ ôn lại ${(forgotten + (total - remembered - forgotten)).clamp(0, total)} ý tưởng.'),
            const Spacer(),
            PrimaryButton(
              label: 'Về trang Notes',
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}

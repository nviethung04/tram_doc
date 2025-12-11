import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  final _items = const [
    (
      'Quản lý tủ sách gọn gàng',
      'Sắp xếp Want to Read / Reading / Read rõ ràng, không bỏ sót.',
      Icons.library_books
    ),
    (
      'Ghi chú & ý tưởng',
      'Lưu ý quan trọng, chuyển thành flashcard để ôn tập nhanh.',
      Icons.sticky_note_2_outlined
    ),
    (
      'Ôn tập ngắt quãng',
      'Flashcard thông minh giúp bạn nhớ lâu, chỉ 2–3 phút mỗi ngày.',
      Icons.bolt_outlined
    ),
  ];

  void _next() {
    if (_index == _items.length - 1) {
      _goToLogin();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _items.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final item = _items[i];
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 64,
                          backgroundColor: AppColors.primary.withOpacity(0.08),
                          child: Icon(item.$3, size: 54, color: AppColors.primary),
                        ),
                        const SizedBox(height: 28),
                        Text(item.$1, style: AppTypography.h1, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text(
                          item.$2,
                          style: AppTypography.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _items.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _index == i ? AppColors.primary : AppColors.inputBorder,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: PrimaryButton(
                label: _index == _items.length - 1 ? 'Bắt đầu' : 'Tiếp tục',
                onPressed: _next,
              ),
            ),
            TextButton(
              onPressed: _goToLogin,
              child: const Text('Đăng nhập'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

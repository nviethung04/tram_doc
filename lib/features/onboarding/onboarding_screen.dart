import 'package:flutter/material.dart';

import '../../components/app_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentIndex = 0;

  final _pages = const [
    _OnboardPage(
      title: 'Chào mừng đến Trạm Đọc',
      description: 'Khám phá kho sách và thẻ ghi nhớ để học nhanh hơn mỗi ngày.',
      imagePath: 'assets/images/onboarding1.png',
    ),
    _OnboardPage(
      title: 'Lưu giữ tiến trình',
      description: 'Đánh dấu, ghi chú và theo dõi thói quen đọc của bạn.',
      imagePath: 'assets/images/onboarding2.png',
    ),
    _OnboardPage(
      title: 'Cá nhân hóa trải nghiệm',
      description: 'Hồ sơ, ảnh đại diện và gợi ý đọc phù hợp sở thích.',
      imagePath: 'assets/images/onboarding3.png',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentIndex == _pages.length - 1) {
      widget.onFinished();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onFinished,
                  child: const Text('Bỏ qua'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            page.imagePath,
                            width: 260,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 260,
                              height: 200,
                              color: AppColors.primary.withOpacity(0.08),
                              alignment: Alignment.center,
                              child: Icon(Icons.image_not_supported, size: 64, color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(page.title, style: AppTypography.h1, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text(
                          page.description,
                          style: AppTypography.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _currentIndex ? AppColors.primary : AppColors.textMuted.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: _currentIndex == _pages.length - 1 ? 'Bắt đầu' : 'Tiếp tục',
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPage {
  final String title;
  final String description;
  final String imagePath;
  const _OnboardPage({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

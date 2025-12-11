import 'package:flutter/material.dart';
import '../../components/primary_app_bar.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import 'book_search_screen.dart';
import 'barcode_screen.dart';

class AddBookMethodScreen extends StatelessWidget {
  const AddBookMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PrimaryAppBar(title: 'Thêm sách', showBack: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: AppSpacing.section),
              _MethodCard(
                iconBg: AppColors.primary.withOpacity(0.1),
                icon: Icons.search,
                title: 'Tìm theo tên / tác giả',
                subtitle: 'Tìm kiếm trong cơ sở dữ liệu sách',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BookSearchScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _MethodCard(
                iconBg: AppColors.accent.withOpacity(0.1),
                icon: Icons.qr_code_scanner,
                title: 'Quét mã vạch (Barcode)',
                subtitle: 'Sử dụng camera để quét mã sách',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BarcodeScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.menu_book_outlined, color: AppColors.primary, size: 40),
          ),
        ),
        const SizedBox(height: 16),
        Text('Chọn cách thêm sách', style: AppTypography.h2, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Tìm kiếm theo tên hoặc quét mã vạch trên sách',
          style: AppTypography.body.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MethodCard({
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyBold.copyWith(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTypography.body.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/session_manager.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _goToEdit(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Cá nhân',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          children: [
            _ProfileHeader(onEditTap: () => _goToEdit(context)),
            const SizedBox(height: 16),
            _SettingsCard(onEditTap: () => _goToEdit(context)),
            const SizedBox(height: 12),
            const _LogoutButton(),
            const SizedBox(height: 8),
            Text('Trạm Đọc v1.0.0', style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final VoidCallback onEditTap;
  const _ProfileHeader({required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage('https://placehold.co/80x80'),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onEditTap,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 6,
                          offset: Offset(0, 4),
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nguyễn Văn An', style: AppTypography.h2),
                const SizedBox(height: 4),
                Text(
                  'Thích sách self-help & productivity',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text('nguyenvanan@email.com', style: AppTypography.caption),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _TagChip(
                      label: 'Tổng sách: 24',
                      color: Color(0xFFEFF6FF),
                      textColor: AppColors.primary,
                    ),
                    _TagChip(
                      label: 'Đã đọc xong: 12',
                      color: Color(0xFFF0FDF4),
                      textColor: Color(0xFF00A63E),
                    ),
                    _TagChip(
                      label: 'Ghi chú: 45',
                      color: Color(0xFFFFFBEB),
                      textColor: Color(0xFFE17100),
                    ),
                    _TagChip(
                      label: 'Flashcards: 38',
                      color: Color(0xFFFAF5FF),
                      textColor: Color(0xFF9810FA),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _TagChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: AppTypography.body.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final VoidCallback onEditTap;
  const _SettingsCard({required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SettingTile(
        icon: Icons.notifications_active_outlined,
        title: 'Thông báo ôn tập',
        subtitle: 'Nhắc nhở hằng ngày',
        activeColor: const Color(0xFF155DFC),
        value: true,
      ),
      _SettingTile(
        icon: Icons.cloud_sync_outlined,
        title: 'Đồng bộ dữ liệu',
        subtitle: 'Đã bật',
        activeColor: const Color(0xFF00A63E),
        value: true,
      ),
      _SettingTile(
        icon: Icons.settings_outlined,
        title: 'Cài đặt khác',
        subtitle: 'Ngôn ngữ, chủ đề...',
        activeColor: AppColors.textMuted,
        value: false,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cài đặt', style: AppTypography.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: item,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color activeColor;
  final bool value;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.activeColor,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: activeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyBold),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          Switch(value: value, onChanged: (_) {}, activeColor: activeColor),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Widget trailing;

  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTypography.bodyBold)),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  Future<void> _handleLogout(BuildContext context) async {
    // Hiển thị dialog xác nhận
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Color(0xFFE7000A)),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      // Xóa session
      await SessionManager().clearLoginTime();

      // Đăng xuất Firebase
      await AuthService().signOut();

      if (!context.mounted) return;

      // Chuyển về màn hình đăng nhập và xóa toàn bộ navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFC9C9)),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Color(0xFFE7000A)),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(
            color: Color(0xFFE7000A),
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () => _handleLogout(context),
      ),
    );
  }
}

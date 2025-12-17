import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/book_service.dart';
import '../../data/services/flashcard_service.dart';
import '../../data/services/notes_service.dart';
import '../../data/services/session_manager.dart';
import '../../data/services/user_service.dart';
import '../../models/app_user.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/image_utils.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _userService = UserService();
  final _bookService = BookService();
  final _notesService = NotesService();
  final _flashcardService = FlashcardService();

  int _totalBooks = 0;
  int _readBooks = 0;
  int _notesCount = 0;
  int _flashcardsCount = 0;
  bool _loadingCounts = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      setState(() => _loadingCounts = false);
      return;
    }

    try {
      final bookStats = await _bookService.getBookStats();
      final totalBooks = bookStats['total'] ?? 0;
      final readBooks = bookStats['read'] ?? 0;
      final notes = await _notesService.getAllNotes();
      final flashcards = await _flashcardService.getAllFlashcards();

      if (!mounted) return;
      setState(() {
        _totalBooks = totalBooks;
        _readBooks = readBooks;
        _notesCount = notes.length;
        _flashcardsCount = flashcards.length;
        _loadingCounts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCounts = false);
    }
  }

  void _goToEdit(BuildContext context, AppUser? user) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
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
      body: StreamBuilder<AppUser?>(
        stream: _userService.streamCurrentUser(),
        builder: (context, snapshot) {
          final appUser = snapshot.data;
          final authUser = _auth.currentUser;
          final displayName = appUser?.displayName ?? authUser?.displayName ?? 'Người dùng';
          final email = appUser?.email ?? authUser?.email ?? 'Chưa cập nhật email';
          final subtitle = appUser?.bio?.trim().isNotEmpty == true
              ? appUser!.bio!
              : 'Chưa có giới thiệu';
          final photoUrl = appUser?.photoUrl ?? authUser?.photoURL ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              children: [
                _ProfileHeader(
                  onEditTap: () => _goToEdit(context, appUser),
                  displayName: displayName,
                  email: email,
                  subtitle: subtitle,
                  photoUrl: photoUrl,
                  totalBooks: _totalBooks,
                  readBooks: _readBooks,
                  notesCount: _notesCount,
                  flashcardsCount: _flashcardsCount,
                  loadingCounts: _loadingCounts,
                ),
                const SizedBox(height: 16),
                _SettingsCard(onEditTap: () => _goToEdit(context, appUser)),
                const SizedBox(height: 12),
                const _LogoutButton(),
                const SizedBox(height: 8),
                Text('Trạm đọc v1.0.0', style: AppTypography.caption),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final VoidCallback onEditTap;
  final String displayName;
  final String email;
  final String subtitle;
  final String? photoUrl;
  final int totalBooks;
  final int readBooks;
  final int notesCount;
  final int flashcardsCount;
  final bool loadingCounts;

  const _ProfileHeader({
    required this.onEditTap,
    required this.displayName,
    required this.email,
    required this.subtitle,
    required this.photoUrl,
    required this.totalBooks,
    required this.readBooks,
    required this.notesCount,
    required this.flashcardsCount,
    required this.loadingCounts,
  });

  @override
  Widget build(BuildContext context) {
    String formatCount(String label, int value) {
      return loadingCounts ? '$label: ...' : '$label: $value';
    }

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
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFEFF1F7),
                backgroundImage: ImageUtils.getImageProvider(photoUrl),
                child: photoUrl == null || photoUrl!.isEmpty
                    ? const Icon(Icons.person, color: AppColors.textMuted, size: 32)
                    : null,
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
                Text(displayName, style: AppTypography.h2),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTypography.body),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(email, style: AppTypography.caption),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TagChip(
                      label: formatCount('Tổng sách', totalBooks),
                      color: const Color(0xFFEFF6FF),
                      textColor: AppColors.primary,
                    ),
                    _TagChip(
                      label: formatCount('Đã đọc xong', readBooks),
                      color: const Color(0xFFF0FDF4),
                      textColor: const Color(0xFF00A63E),
                    ),
                    _TagChip(
                      label: formatCount('Ghi chú', notesCount),
                      color: const Color(0xFFFFFBEB),
                      textColor: const Color(0xFFE17100),
                    ),
                    _TagChip(
                      label: formatCount('Flashcards', flashcardsCount),
                      color: const Color(0xFFFAF5FF),
                      textColor: const Color(0xFF9810FA),
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
        title: 'Thông báo ăn tập',
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onEditTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Chỉnh sửa hồ sơ', style: TextStyle(color: Colors.white)),
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
              color: activeColor.withOpacity(0.12),
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
          Switch(value: value, onChanged: (_) {}),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  Future<void> _handleLogout(BuildContext context) async {
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
      await SessionManager().clearLoginTime();
      await AuthService().signOut();

      if (!context.mounted) return;

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

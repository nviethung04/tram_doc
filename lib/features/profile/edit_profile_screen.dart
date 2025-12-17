import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../components/app_button.dart';
import '../../components/app_input.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';
import '../../models/app_user.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.user});

  final AppUser? user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _authService = AuthService();
  final _userService = UserService();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();

  String? _photoUrl;
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authUser = FirebaseAuth.instance.currentUser;
    final appUser = widget.user ?? await _userService.getCurrentUser();

    setState(() {
      _nameController.text = appUser?.displayName ?? authUser?.displayName ?? '';
      _bioController.text = appUser?.bio ?? '';
      _emailController.text = appUser?.email ?? authUser?.email ?? '';
      _photoUrl = appUser?.photoUrl ?? authUser?.photoURL;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotoUrl() async {
    final controller = TextEditingController(text: _photoUrl ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập URL ảnh đại diện'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'https://...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Chọn')),
        ],
      ),
    );

    if (result != null) {
      setState(() => _photoUrl = result);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập tên hiển thị');
      return;
    }

    setState(() => _saving = true);

    try {
      await _authService.updateProfile(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        email: _emailController.text.trim(),
        photoUrl: _photoUrl,
      );

      if (!mounted) return;
      _showMessage('Đã lưu hồ sơ');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: const Color(0xFFEFF1F7),
                              backgroundImage:
                                  _photoUrl != null && _photoUrl!.isNotEmpty ? NetworkImage(_photoUrl!) : null,
                              child: _photoUrl == null || _photoUrl!.isEmpty
                                  ? const Icon(Icons.person, size: 40, color: AppColors.textMuted)
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 4,
                              child: GestureDetector(
                                onTap: _pickPhotoUrl,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(17),
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
                                  child: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Thay đổi ảnh đại diện',
                            style: AppTypography.bodyBold.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        LabeledInput(label: 'Tên hiển thị', controller: _nameController),
                        const SizedBox(height: 14),
                        LabeledInput(label: 'Giới thiệu', controller: _bioController),
                        const SizedBox(height: 14),
                        LabeledInput(
                          label: 'Email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: _saving ? 'Đang lưu...' : 'Lưu thay đổi',
                      onPressed: _saving ? null : _save,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

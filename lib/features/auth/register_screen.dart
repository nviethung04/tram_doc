import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../components/app_input.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/session_manager.dart';
import '../../theme/app_typography.dart';
import '../shell/app_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('Vui lòng nhập tên');
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showErrorDialog('Vui lòng nhập email');
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showErrorDialog('Email không hợp lệ');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showErrorDialog('Vui lòng nhập mật khẩu');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showErrorDialog('Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Mật khẩu xác nhận không khớp');
      return;
    }

    if (!_agreedToTerms) {
      _showErrorDialog('Vui lòng đồng ý với Điều khoản sử dụng');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.registerWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      // Lưu thời gian đăng nhập
      await SessionManager().saveLoginTime();

      if (!mounted) return;

      // Đăng ký thành công, chuyển đến màn hình chính
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tạo tài khoản', style: AppTypography.h1),
              const SizedBox(height: 8),
              Text('Chào mừng bạn đến Trạm Đọc.', style: AppTypography.body),
              const SizedBox(height: 24),
              LabeledInput(
                label: 'Tên',
                hint: 'Nguyễn Văn A',
                controller: _nameController,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),
              LabeledInput(
                label: 'Email',
                hint: 'name@email.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              LabeledInput(
                label: 'Mật khẩu',
                hint: '••••••••',
                obscureText: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 16),
              LabeledInput(
                label: 'Xác nhận mật khẩu',
                hint: '••••••••',
                obscureText: true,
                controller: _confirmPasswordController,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() => _agreedToTerms = value ?? false);
                    },
                  ),
                  const Expanded(
                    child: Text('Tôi đồng ý với Điều khoản sử dụng'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: _isLoading ? 'Đang xử lý...' : 'Tạo tài khoản',
                onPressed: _isLoading ? null : _register,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

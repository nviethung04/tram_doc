import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../components/app_input.dart';
import '../../theme/app_typography.dart';
import '../shell/app_shell.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
              const LabeledInput(label: 'Tên', hint: 'Nguyễn Văn A'),
              const SizedBox(height: 16),
              const LabeledInput(label: 'Email', hint: 'name@email.com'),
              const SizedBox(height: 16),
              const LabeledInput(label: 'Mật khẩu', hint: '••••••••', obscureText: true),
              const SizedBox(height: 16),
              const LabeledInput(label: 'Xác nhận mật khẩu', hint: '••••••••', obscureText: true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(value: true, onChanged: (_) {}),
                  const Expanded(child: Text('Tôi đồng ý với Điều khoản sử dụng')),
                ],
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Tạo tài khoản',
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AppShell()),
                    (_) => false,
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

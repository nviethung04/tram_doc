import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../components/app_input.dart';
import '../../theme/app_typography.dart';
import '../shell/app_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chào mừng trở lại', style: AppTypography.h1),
              const SizedBox(height: 8),
              Text('Tiếp tục hành trình đọc của bạn.', style: AppTypography.body),
              const SizedBox(height: 24),
              const LabeledInput(label: 'Email / Số điện thoại', hint: 'name@email.com'),
              const SizedBox(height: 16),
              const LabeledInput(label: 'Mật khẩu', hint: '••••••••', obscureText: true),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () {}, child: const Text('Quên mật khẩu?')),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Đăng nhập',
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AppShell()),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản?'),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text('Đăng ký'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

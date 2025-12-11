import 'package:flutter/material.dart';
import '../../components/app_button.dart';
import '../../components/app_input.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../shell/app_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _goToRegister(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  void _login(BuildContext context) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              // Logo + intro block
              Column(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 6,
                          offset: Offset(0, 4),
                          spreadRadius: -4,
                        ),
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 15,
                          offset: Offset(0, 10),
                          spreadRadius: -3,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.menu_book, color: AppColors.primary, size: 30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Trạm Đọc',
                    textAlign: TextAlign.center,
                    style: AppTypography.h1.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chào mừng trở lại!',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      fontSize: 16,
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Form
              const LabeledInput(
                label: 'Email',
                hint: 'name@email.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              const LabeledInput(
                label: 'Mật khẩu',
                hint: '••••••••',
                obscureText: true,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Quên mật khẩu?'),
                ),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Đăng nhập',
                onPressed: () => _login(context),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản?'),
                  TextButton(
                    onPressed: () => _goToRegister(context),
                    child: const Text('Đăng ký'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

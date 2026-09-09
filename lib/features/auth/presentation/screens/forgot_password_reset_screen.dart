import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/auth/presentation/widgets/forgot_password_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// `login-forgot-password-baru`: step 3 (final) of the forgot-password flow —
/// set a new password.
///
/// TODO(open-question): no backend endpoint to submit the new password is
/// documented yet. "Lanjutkan" returns to the login screen once both fields
/// are filled and match; wire the real request once the endpoint exists.
class ForgotPasswordResetScreen extends StatefulWidget {
  const ForgotPasswordResetScreen({super.key});

  @override
  State<ForgotPasswordResetScreen> createState() =>
      _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState
    extends State<ForgotPasswordResetScreen> {
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  String? _validationMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _onLanjutkan() {
    final password = _passwordController.text;
    final newPassword = _newPasswordController.text;
    if (password.isEmpty || newPassword.isEmpty) {
      setState(() => _validationMessage = 'Password wajib diisi.');
      return;
    }
    if (password != newPassword) {
      setState(() => _validationMessage = 'Password tidak cocok.');
      return;
    }
    setState(() => _validationMessage = null);
    context.goNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          ForgotPasswordNavBar(
            title: 'Buat Password Baru',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Image.asset(
                      'assets/images/forgot-password-reset.png',
                      width: 80,
                      height: 80,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 47),
                      child: Text(
                        'Kata sandi baru Anda harus berbeda dari kata sandi '
                        'sebelumnya.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.neutral900,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppInput(
                            controller: _passwordController,
                            label: 'Password',
                            hintText: 'Masukkan Password',
                            leadingIcon: Icons.lock_outline,
                            obscureText: true,
                          ),
                          const SizedBox(height: 24),
                          AppInput(
                            controller: _newPasswordController,
                            label: 'New Password',
                            hintText: 'Masukkan Password',
                            leadingIcon: Icons.lock_outline,
                            obscureText: true,
                          ),
                          if (_validationMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _validationMessage!,
                              style: const TextStyle(
                                color: AppColors.dangerRed,
                                fontSize: 14,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: 'Lanjutkan',
                            onPressed: _onLanjutkan,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

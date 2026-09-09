import 'dart:async';

import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/auth/presentation/widgets/forgot_password_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// `login-forgot`: step 1 of the forgot-password flow — enter the email to
/// receive a reset OTP.
///
/// TODO(open-question): no backend endpoint to request a password-reset OTP
/// is documented yet (see `docs/api-reference.md`). "Kirim Kode" advances the
/// flow locally with the entered email; wire the real request once the
/// endpoint exists.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _validationMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onKirimKode() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _validationMessage = 'Email wajib diisi.');
      return;
    }
    setState(() => _validationMessage = null);
    unawaited(context.pushNamed(AppRoutes.forgotPasswordVerify, extra: email));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          ForgotPasswordNavBar(
            title: 'Lupa Password ?',
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
                      'assets/images/forgot-password-email.png',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 47),
                      child: Text(
                        'Masukkan email yang terdaftar untuk mengatur ulang '
                        'password.',
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
                            controller: _emailController,
                            label: 'Email',
                            hintText: 'Masukkan Email',
                            leadingIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
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
                            label: 'Kirim Kode',
                            onPressed: _onKirimKode,
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

import 'dart:async';

import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/auth/data/repositories/auth_repository.dart';
import 'package:dtw_app/features/auth/presentation/widgets/forgot_password_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// `login-forgot`: step 1 of the forgot-password flow — enter the email to
/// receive a reset token (`POST /v1/auth/forgot-password`).
///
/// The endpoint's response is identical whether or not the entered email
/// has an account (anti-enumeration, per `api-auth-device-external.md`) —
/// "Kirim Kode" always advances to the OTP step on a successful call,
/// regardless of whether an email actually went out. Only a network failure,
/// a malformed email, or the rate limit (429) surface as an error here.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _validationMessage;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onKirimKode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _validationMessage = 'Email wajib diisi.');
      return;
    }
    setState(() {
      _validationMessage = null;
      _submitting = true;
    });
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email: email);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _validationMessage = errorMessage(error);
      });
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);
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
                            onPressed: _submitting
                                ? null
                                : () => unawaited(_onKirimKode()),
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

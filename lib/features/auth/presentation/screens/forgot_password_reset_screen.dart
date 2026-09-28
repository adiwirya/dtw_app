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

/// `login-forgot-password-baru`: step 3 (final) of the forgot-password flow —
/// set a new password (`POST /v1/auth/reset-password`) using the [email] and
/// [token] carried forward from steps 1–2.
///
/// A successful reset revokes every other active session for this account
/// server-side (per `api-auth-device-external.md`) — this device isn't
/// logged in yet at this point, so nothing local needs clearing here.
/// "Lanjutkan" returns to the login screen on success.
class ForgotPasswordResetScreen extends ConsumerStatefulWidget {
  const ForgotPasswordResetScreen({
    required this.email,
    required this.token,
    super.key,
  });

  final String email;
  final String token;

  @override
  ConsumerState<ForgotPasswordResetScreen> createState() =>
      _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState
    extends ConsumerState<ForgotPasswordResetScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _validationMessage;
  bool _submitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onLanjutkan() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (password.isEmpty || confirm.isEmpty) {
      setState(() => _validationMessage = 'Password wajib diisi.');
      return;
    }
    if (password.length < 8) {
      setState(() => _validationMessage = 'Password minimal 8 karakter.');
      return;
    }
    if (password != confirm) {
      setState(() => _validationMessage = 'Password tidak cocok.');
      return;
    }
    setState(() {
      _validationMessage = null;
      _submitting = true;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: widget.email,
            token: widget.token,
            password: password,
            passwordConfirmation: confirm,
          );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _validationMessage = errorMessage(error);
      });
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password berhasil diubah.')),
    );
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
                            label: 'Password Baru',
                            hintText: 'Masukkan Password Baru',
                            leadingIcon: Icons.lock_outline,
                            obscureText: true,
                          ),
                          const SizedBox(height: 24),
                          AppInput(
                            controller: _confirmController,
                            label: 'Konfirmasi Password Baru',
                            hintText: 'Ulangi Password Baru',
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
                            onPressed: _submitting
                                ? null
                                : () => unawaited(_onLanjutkan()),
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

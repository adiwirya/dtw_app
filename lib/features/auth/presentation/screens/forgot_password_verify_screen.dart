import 'dart:async';

import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/auth/data/repositories/auth_repository.dart';
import 'package:dtw_app/features/auth/presentation/widgets/forgot_password_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// `login-forgot-verifikasi`: step 2 of the forgot-password flow — enter the
/// 6-digit token sent to the [email] from step 1.
///
/// `api-auth-device-external.md` has no separate "verify token" endpoint —
/// the token is only checked together with the new password on
/// `POST /v1/auth/reset-password` (step 3). "Verifikasi Kode" is therefore
/// local validation only (all 6 digits entered); the digits are carried
/// forward as the `token` for that call. "Kirim Ulang" re-calls
/// `forgotPassword` to send a fresh token.
class ForgotPasswordVerifyScreen extends ConsumerStatefulWidget {
  const ForgotPasswordVerifyScreen({required this.email, super.key});

  final String email;

  @override
  ConsumerState<ForgotPasswordVerifyScreen> createState() =>
      _ForgotPasswordVerifyScreenState();
}

class _ForgotPasswordVerifyScreenState
    extends ConsumerState<ForgotPasswordVerifyScreen> {
  static const _digitCount = 6;
  final List<TextEditingController> _controllers = List.generate(
    _digitCount,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _digitCount,
    (_) => FocusNode(),
  );
  String? _validationMessage;
  bool _resending = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < _digitCount - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _onVerifikasiKode() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < _digitCount) {
      setState(() => _validationMessage = 'Masukkan 6 digit kode.');
      return;
    }
    setState(() => _validationMessage = null);
    // `push`, not `go`: a `go` to a nested route rebuilds every ancestor
    // route in the stack (forgot-password, verify) against this SAME
    // `state.extra`, and `verify`'s builder casts it as `String?` — passing
    // the `(email, code)` record that way throws a cast error there. `push`
    // adds this page on top instead, leaving the ancestors' own extras
    // alone.
    unawaited(
      context.pushNamed(
        AppRoutes.forgotPasswordReset,
        extra: (widget.email, code),
      ),
    );
  }

  Future<void> _onKirimUlang() async {
    if (_resending) return;
    setState(() => _resending = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .forgotPassword(email: widget.email);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage(error))));
      setState(() => _resending = false);
      return;
    }
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kode baru sudah dikirim ke email Anda.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          ForgotPasswordNavBar(
            title: 'Verifikasi',
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
                      'assets/images/forgot-password-otp.png',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            color: AppColors.neutral900,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Kami telah mengirim kode ke\n',
                            ),
                            TextSpan(
                              text: widget.email,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Masukkan kode 6 digit dari email Anda',
                            style: TextStyle(
                              color: AppColors.neutral900,
                              fontSize: 14,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              for (var i = 0; i < _digitCount; i++) ...[
                                if (i > 0) const SizedBox(width: 8),
                                Expanded(child: _OtpBox(
                                  controller: _controllers[i],
                                  focusNode: _focusNodes[i],
                                  onChanged: (v) => _onDigitChanged(i, v),
                                )),
                              ],
                            ],
                          ),
                        ],
                      ),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: PrimaryButton(
                        label: 'Verifikasi Kode',
                        onPressed: _onVerifikasiKode,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _resending
                          ? null
                          : () => unawaited(_onKirimUlang()),
                      child: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Tidak Menerima Kode ? ',
                              style: TextStyle(
                                color: AppColors.neutral900,
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(
                              text: 'Kirim Ulang',
                              style: TextStyle(
                                color: AppColors.successGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
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

/// One digit box of the OTP row (`Rectangle 2317`): 51-tall, 12-radius,
/// `otpBoxBorder`-bordered, single-digit centered entry.
class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 51,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.otpBoxBorder),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          color: AppColors.neutral900,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}

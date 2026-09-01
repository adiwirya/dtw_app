import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The login screen — the app's single shared entry point, hosted on `/login`.
///
/// Tapping "Masuk" always calls the real login API via `AuthController`. The
/// response's `data.user.role` is what lands the single merged router on the
/// tenant or the busboy shell (see `homePathFor` in `core/router/`), not a
/// role picked up front on this screen — there is no role selector here. The
/// response's `scopes` are recorded alongside it because every
/// branch/zone-scoped call still needs them.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  String? _validationMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onMasuk() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _validationMessage = 'Username dan password wajib diisi.');
      return;
    }
    setState(() => _validationMessage = null);

    await ref
        .read(authControllerProvider.notifier)
        .login(
          username: username,
          password: password,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Top hero gradient (Rectangle 367, 390x255).
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 255,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.heroGradientTop, AppColors.white],
                  stops: [0, 0.66],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Real OS status-bar inset. A fake `9:41` bar used to
                  // sit here, doubling up with the real one on device.
                  SizedBox(height: MediaQuery.paddingOf(context).top),
                  _buildHeaderBand(),
                  const SizedBox(height: 24),
                  _buildForm(authState),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBand() {
    return SizedBox(
      height: 149,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Storefront hero, right-aligned.
          Positioned(
            top: 28,
            right: 16,
            child: Image.asset(
              'assets/images/login-hero.png',
              width: 151,
              height: 121,
            ),
          ),
          // Brand wordmark + subtitle, left-aligned. "DTW" takes the app's
          // Open Sans from the theme; "Order" is Pacifico, the one place the
          // design uses a second family.
          const Positioned(
            top: 46,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'DTW ',
                        style: TextStyle(
                          color: AppColors.neutral900,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      TextSpan(
                        text: 'Order',
                        style: TextStyle(
                          fontFamily: 'Pacifico',
                          color: AppColors.success700,
                          fontSize: 30,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Pesan Cepat, Nikmati Sekarang',
                  style: TextStyle(
                    color: AppColors.neutral500,
                    fontSize: 14,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AuthState authState) {
    final error = authState.error;
    final errorMessage =
        _validationMessage ??
        (error == null
            ? null
            : (error is AuthException
                  ? error.message
                  : 'Terjadi kesalahan. Coba lagi.'));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(
            controller: _usernameController,
            label: 'Username',
            hintText: 'Masukkan username',
            leadingIcon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          AppInput(
            controller: _passwordController,
            label: 'Password',
            hintText: 'Masukkan password',
            leadingIcon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          _buildRememberRow(),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage,
              style: const TextStyle(color: AppColors.dangerRed, fontSize: 14),
            ),
          ],
          const SizedBox(height: 40),
          PrimaryButton(
            label: 'Masuk',
            onPressed: authState.isLoading ? null : _onMasuk,
          ),
        ],
      ),
    );
  }

  Widget _buildRememberRow() {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RememberCheckbox(checked: _rememberMe),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Ingat Saya',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.neutral900,
                        fontSize: 14,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            // TODO(open-question): "Lupa Password?" has no destination yet.
            onTap: () {},
            child: const Text(
              'Lupa Password ?',
              style: TextStyle(
                color: AppColors.successGreen,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RememberCheckbox extends StatelessWidget {
  const _RememberCheckbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: checked ? AppColors.successGreen : AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: checked ? AppColors.successGreen : AppColors.neutral100,
          width: 1.5,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 14, color: AppColors.white)
          : null,
    );
  }
}

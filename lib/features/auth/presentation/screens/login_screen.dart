import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:dtw_app/features/auth/presentation/widgets/login_status_bar.dart';
import 'package:dtw_app/features/auth/presentation/widgets/role_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The login screen, modelled as a two-step flow over the existing `/login`
/// and `/login/tenant` routes:
///
/// * `/login` (`login-default`) builds `LoginScreen()` with no role selected.
///   Tapping a role card navigates to `/login/tenant`.
/// * `/login/tenant` (`login-tenantt`) builds `LoginScreen(initialRole: ...)`
///   with a role pre-selected; tapping cards re-selects locally.
///
/// This is the busboy flavor's entrypoint, so the Busboy card is the primary
/// CTA and is the role `/login/tenant` pre-selects. It also doubles as the
/// app's single shared entry: tapping "Masuk" sets [appFlavorProvider] from
/// the selected role, so picking **Tenan** switches the whole app to the
/// tenant router (landing on its Order tab) instead of staying on busboy's.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({this.initialRole, super.key});

  /// When non-null the screen renders the `login-tenantt` step with this role
  /// pre-selected. When null it renders the `login-default` step.
  final LoginRole? initialRole;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  LoginRole? _selectedRole;
  bool _rememberMe = false;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRoleTap(LoginRole role) {
    if (widget.initialRole == null) {
      // Default step: tapping any role reveals the login-tenant step.
      context.goNamed(AppRoutes.loginTenant);
    } else {
      // Tenant step: re-select the highlighted role.
      setState(() => _selectedRole = role);
    }
  }

  Future<void> _onMasuk() async {
    final effectiveRole = _selectedRole ?? LoginRole.busboy;
    if (effectiveRole == LoginRole.tenan) {
      // Tenant login is card/NFC-based and out of scope here — keep the
      // existing mock flavor switch until that spec lands.
      ref.read(isLoggedInProvider.notifier).state = true;
      ref.read(appFlavorProvider.notifier).state = AppFlavor.tenant;
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _validationMessage = 'Username dan password wajib diisi.');
      return;
    }
    setState(() => _validationMessage = null);

    await ref.read(authControllerProvider.notifier).login(
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
                  const LoginStatusBar(),
                  _buildHeaderBand(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Masuk Sebagai',
                      // TODO(open-question): Open Sans Bold in the cache.
                      style: TextStyle(
                        color: AppColors.neutral900,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  _buildRoleCards(),
                  // 24px design gap + 3px to offset the shared AppInput label
                  // rendering ~2px shorter per field than the cached Input.
                  const SizedBox(height: 27),
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
          // Brand wordmark + subtitle, left-aligned.
          // TODO(open-question): the "Order" wordmark is Pacifico and "DTW" is
          // Open Sans in the cache; neither font is bundled yet, so both use
          // the default family (green accent preserved).
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
                          color: AppColors.success700,
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Aplikasi Tenan & Bosboy',
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

  Widget _buildRoleCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: RoleCard(
              title: 'Tenan',
              description: 'Kelola Pesanan & Menu',
              assetPath: 'assets/images/role-tenan.png',
              selected: _selectedRole == LoginRole.tenan,
              onTap: () => _onRoleTap(LoginRole.tenan),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: RoleCard(
              title: 'Busboy',
              description: 'Antar pesanan ke pelanggan',
              assetPath: 'assets/images/role-busboy.png',
              selected: _selectedRole == LoginRole.busboy,
              onTap: () => _onRoleTap(LoginRole.busboy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AuthState authState) {
    final error = authState.error;
    final errorMessage = _validationMessage ??
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

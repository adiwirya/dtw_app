import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/auth/presentation/widgets/login_status_bar.dart';
import 'package:dtw_app/features/auth/presentation/widgets/role_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The **tenant** flavor login screen, modelled as a two-step flow over the
/// tenant `/login` and `/login/tenant` routes:
///
/// * `/login` (`login-default`) builds `TenantLoginScreen()` with no role
///   selected. Tapping a role card navigates to `/login/tenant`.
/// * `/login/tenant` (`login-tenantt`) builds
///   `TenantLoginScreen(initialRole: LoginRole.tenan)` with the Tenan role
///   pre-selected; tapping cards re-selects locally.
///
/// This mirrors the busboy `LoginScreen` but reproduces the tenant reference,
/// which differs from busboy in three ways: (1) an extra "Pilih Tenant"
/// dropdown field sits above Username, (2) the card / subtitle copy reads
/// "Tenant" / "Aplikasi Tenant & Bosboy" (busboy uses "Tenan"), and (3) the
/// Tenan card is the pre-selected primary CTA. It reuses the shared
/// [LoginStatusBar], [RoleCard], [AppInput] and [PrimaryButton] pieces so the
/// design system stays single-sourced; a dedicated screen (rather than
/// parameterizing the shared widget) keeps the busboy login untouched.
///
/// This is the tenant flavor, so the Tenan card is the primary CTA and the role
/// `/login/tenant` pre-selects. Tapping "Masuk" sets [appFlavorProvider] from
/// the selected role, same as the busboy `LoginScreen` — picking **Busboy**
/// here switches the whole app back to the busboy router on its Order tab.
class TenantLoginScreen extends ConsumerStatefulWidget {
  const TenantLoginScreen({this.initialRole, super.key});

  /// When non-null the screen renders the `login-tenantt` step with this role
  /// pre-selected. When null it renders the `login-default` step.
  final LoginRole? initialRole;

  @override
  ConsumerState<TenantLoginScreen> createState() => _TenantLoginScreenState();
}

class _TenantLoginScreenState extends ConsumerState<TenantLoginScreen> {
  final _tenantController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  LoginRole? _selectedRole;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _tenantController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRoleTap(LoginRole role) {
    if (widget.initialRole == null) {
      // Default step: tapping any role reveals the login-tenantt step (which
      // pre-selects the Tenan primary role for this flavor).
      context.goNamed(TenantRoutes.loginTenant);
    } else {
      // Tenant step: re-select the highlighted role.
      setState(() => _selectedRole = role);
    }
  }

  void _onMasuk() {
    // TODO(open-question): auth is out of scope (Open Question 1) — "Masuk"
    // only picks the flavor matching the selected role; no credential
    // validation is performed.
    ref.read(isLoggedInProvider.notifier).state = true;
    ref.read(appFlavorProvider.notifier).state =
        (_selectedRole ?? LoginRole.tenan) == LoginRole.busboy
            ? AppFlavor.busboy
            : AppFlavor.tenant;
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildForm(),
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
                // Tenant flavor subtitle (busboy reads "Aplikasi Tenan …").
                Text(
                  'Aplikasi Tenant & Bosboy',
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
            // Tenant flavor card copy reads "Tenant" (busboy uses "Tenan").
            child: RoleCard(
              title: 'Tenant',
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

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tenant-only "Pilih Tenant" dropdown (store icon + chevron).
          // TODO(open-question): the tenant picker is a static stub — no tenant
          // list / selection sheet yet (auth + data out of scope).
          AppInput(
            controller: _tenantController,
            label: 'Pilih Tenant',
            hintText: 'Pilih Tenant',
            leadingIcon: Icons.storefront_outlined,
            enabled: false,
            trailing: const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 40),
          PrimaryButton(label: 'Masuk', onPressed: _onMasuk),
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

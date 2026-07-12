import 'package:dtw_app/core/widgets/app_shell.dart';
import 'package:dtw_app/core/widgets/order_card.dart';
import 'package:dtw_app/core/widgets/placeholder_screen.dart';
import 'package:dtw_app/features/akun/presentation/screens/akun_screen.dart';
import 'package:dtw_app/features/akun/presentation/screens/profile_saya_screen.dart';
import 'package:dtw_app/features/auth/presentation/screens/login_screen.dart';
import 'package:dtw_app/features/auth/presentation/widgets/role_card.dart';
import 'package:dtw_app/features/order/presentation/providers/order_provider.dart';
import 'package:dtw_app/features/order/presentation/screens/order_detail_screen.dart';
import 'package:dtw_app/features/order/presentation/screens/order_screen.dart';
import 'package:dtw_app/features/order/presentation/screens/order_selesai_detail_screen.dart';
import 'package:dtw_app/features/performa/presentation/screens/performa_screen.dart';
import 'package:dtw_app/features/performa/presentation/screens/performa_v2_screen.dart';
import 'package:dtw_app/features/riwayat/data/models/riwayat_models.dart';
import 'package:dtw_app/features/riwayat/presentation/providers/riwayat_provider.dart';
import 'package:dtw_app/features/riwayat/presentation/screens/riwayat_detail_screen.dart';
import 'package:dtw_app/features/riwayat/presentation/screens/riwayat_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Named routes for the busboy app.
///
/// Later work items (02–12) replace the placeholder `builder:` for each route
/// with the real screen — keep these names/paths stable so callers
/// (`context.goNamed(...)`) don't need to change.
abstract class AppRoutes {
  // --- Auth (outside the bottom-nav shell) ---
  static const login = 'login'; // login-default
  static const loginTenant = 'loginTenant'; // login-tenantt

  // --- Tab 0: Order (home = menu-order-baru) ---
  static const order = 'order'; // menu-order-baru
  static const orderDetail = 'orderDetail'; // menu-order-baru-2
  static const orderAntar = 'orderAntar'; // menu-order-antar
  static const orderBerhasil = 'orderBerhasil'; // berhasil-ditambahkan (modal)
  static const orderSelesai = 'orderSelesai'; // menu-order-selesai
  static const orderSelesaiDetail = 'orderSelesaiDetail'; // detail-selesai
  static const orderSelesaiBerhasil =
      'orderSelesaiBerhasil'; // berhasil-ditambahkan-2 (modal)

  // --- Tab 1: Performa (home = performa-v1) ---
  static const performa = 'performa'; // performa-v1
  static const performaV2 = 'performaV2'; // performa-v2

  // --- Tab 2: Riwayat (home = riwayat-hari-ini) ---
  static const riwayat = 'riwayat'; // riwayat-hari-ini
  static const riwayatKemarin = 'riwayatKemarin'; // riwayat-kemarin
  static const riwayat7Hari = 'riwayat7Hari'; // riwayat-7-hari
  static const riwayatDetail = 'riwayatDetail'; // detail-riwayat

  // --- Tab 3: Akun (home = akun) ---
  static const akun = 'akun'; // akun
  static const akunProfile = 'akunProfile'; // profile-saya

  // Path used as the post-login landing location (Order tab).
  static const orderPath = '/order';
  static const loginPath = '/login';
}

/// Deep-link shim for `/order/antar` and `/order/selesai`: selects the matching
/// Order sub-tab on the shared provider, then renders the in-place
/// [OrderScreen] (the primary UX is switching sub-tabs in place on `/order`).
class _OrderTabDeepLink extends ConsumerStatefulWidget {
  const _OrderTabDeepLink({required this.status});

  final OrderStatus status;

  @override
  ConsumerState<_OrderTabDeepLink> createState() => _OrderTabDeepLinkState();
}

class _OrderTabDeepLinkState extends ConsumerState<_OrderTabDeepLink> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderTabProvider.notifier).selectStatus(widget.status);
    });
  }

  @override
  Widget build(BuildContext context) => const OrderScreen();
}

/// Deep-link shim for `/riwayat/kemarin` and `/riwayat/7-hari`: selects the
/// matching Riwayat date tab on the shared provider, then renders the in-place
/// [RiwayatScreen] (the primary UX is switching date tabs in place on
/// `/riwayat`).
class _RiwayatTabDeepLink extends ConsumerStatefulWidget {
  const _RiwayatTabDeepLink({required this.range});

  final RiwayatRange range;

  @override
  ConsumerState<_RiwayatTabDeepLink> createState() =>
      _RiwayatTabDeepLinkState();
}

class _RiwayatTabDeepLinkState extends ConsumerState<_RiwayatTabDeepLink> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riwayatTabProvider.notifier).selectRange(widget.range);
    });
  }

  @override
  Widget build(BuildContext context) => const RiwayatScreen();
}

@riverpod
GoRouter appRouter(Ref ref) => GoRouter(
      // Post-login lands on the Order tab; see login-tenantt → menu-order-baru
      // in the prototype flow.
      initialLocation: AppRoutes.loginPath,
      routes: [
        // Login sits OUTSIDE the shell (root navigator, no bottom nav).
        GoRoute(
          path: AppRoutes.loginPath,
          name: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
          routes: [
            GoRoute(
              path: 'tenant',
              name: AppRoutes.loginTenant,
              builder: (context, state) =>
                  const LoginScreen(initialRole: LoginRole.busboy),
            ),
          ],
        ),

        // Persistent 4-tab bottom-nav shell.
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            // Tab 0 — Order.
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.orderPath,
                  name: AppRoutes.order,
                  builder: (context, state) => const OrderScreen(),
                  routes: [
                    GoRoute(
                      path: 'detail',
                      name: AppRoutes.orderDetail,
                      builder: (context, state) => const OrderDetailScreen(),
                    ),
                    // The Order home shows all three sub-tabs in place; these
                    // routes deep-link into the right sub-tab by setting the
                    // shared tab provider, then render the same screen.
                    GoRoute(
                      path: 'antar',
                      name: AppRoutes.orderAntar,
                      builder: (context, state) =>
                          const _OrderTabDeepLink(status: OrderStatus.antar),
                    ),
                    GoRoute(
                      path: 'berhasil',
                      name: AppRoutes.orderBerhasil,
                      builder: (context, state) => const PlaceholderScreen(
                        title: 'Berhasil Ditambahkan',
                      ),
                    ),
                    GoRoute(
                      path: 'selesai',
                      name: AppRoutes.orderSelesai,
                      builder: (context, state) =>
                          const _OrderTabDeepLink(status: OrderStatus.selesai),
                      routes: [
                        GoRoute(
                          path: 'detail',
                          name: AppRoutes.orderSelesaiDetail,
                          builder: (context, state) =>
                              const OrderSelesaiDetailScreen(),
                        ),
                        GoRoute(
                          path: 'berhasil',
                          name: AppRoutes.orderSelesaiBerhasil,
                          builder: (context, state) => const PlaceholderScreen(
                            title: 'Berhasil Ditambahkan (Selesai)',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Tab 1 — Performa.
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/performa',
                  name: AppRoutes.performa,
                  builder: (context, state) => const PerformaScreen(),
                  routes: [
                    GoRoute(
                      path: 'v2',
                      name: AppRoutes.performaV2,
                      builder: (context, state) => const PerformaV2Screen(),
                    ),
                  ],
                ),
              ],
            ),

            // Tab 2 — Riwayat.
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/riwayat',
                  name: AppRoutes.riwayat,
                  builder: (context, state) => const RiwayatScreen(),
                  routes: [
                    // The Riwayat home shows all three date tabs in place;
                    // these routes deep-link into the right tab by setting the
                    // shared tab provider, then render the same screen.
                    GoRoute(
                      path: 'kemarin',
                      name: AppRoutes.riwayatKemarin,
                      builder: (context, state) => const _RiwayatTabDeepLink(
                        range: RiwayatRange.kemarin,
                      ),
                    ),
                    GoRoute(
                      path: '7-hari',
                      name: AppRoutes.riwayat7Hari,
                      builder: (context, state) => const _RiwayatTabDeepLink(
                        range: RiwayatRange.tujuhHari,
                      ),
                    ),
                    GoRoute(
                      path: 'detail',
                      name: AppRoutes.riwayatDetail,
                      builder: (context, state) => const RiwayatDetailScreen(),
                    ),
                  ],
                ),
              ],
            ),

            // Tab 3 — Akun.
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/akun',
                  name: AppRoutes.akun,
                  builder: (context, state) => const AkunScreen(),
                  routes: [
                    GoRoute(
                      path: 'profile',
                      name: AppRoutes.akunProfile,
                      builder: (context, state) => const ProfileSayaScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

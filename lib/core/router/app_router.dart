import 'dart:async';

import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/widgets/app_shell.dart';
import 'package:dtw_app/core/widgets/order_card.dart';
import 'package:dtw_app/core/widgets/success_modal.dart';
import 'package:dtw_app/features/akun/presentation/screens/akun_screen.dart';
import 'package:dtw_app/features/akun/presentation/screens/profile_saya_screen.dart';
import 'package:dtw_app/features/auth/presentation/screens/login_screen.dart';
import 'package:dtw_app/features/order/data/models/order_models.dart';
import 'package:dtw_app/features/order/presentation/providers/order_provider.dart';
import 'package:dtw_app/features/order/presentation/screens/order_detail_screen.dart';
import 'package:dtw_app/features/order/presentation/screens/order_screen.dart';
import 'package:dtw_app/features/order/presentation/screens/order_selesai_detail_screen.dart';
import 'package:dtw_app/features/order/presentation/widgets/order_success_details.dart';
import 'package:dtw_app/features/performa/presentation/screens/performa_screen.dart';
import 'package:dtw_app/features/performa/presentation/screens/performa_v2_screen.dart';
import 'package:dtw_app/features/riwayat/data/models/riwayat_models.dart';
import 'package:dtw_app/features/riwayat/presentation/providers/riwayat_provider.dart';
import 'package:dtw_app/features/riwayat/presentation/screens/riwayat_detail_screen.dart';
import 'package:dtw_app/features/riwayat/presentation/screens/riwayat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Named routes for the busboy shell.
///
/// Later work items (02–12) replace the placeholder `builder:` for each route
/// with the real screen — keep these names/paths stable so callers
/// (`context.goNamed(...)`) don't need to change.
abstract class AppRoutes {
  // --- Auth (outside the bottom-nav shell; shared with the tenant shell — see
  // `appRouter` below) ---
  static const login = 'login'; // login-default

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

/// Deep-link shim for the two `berhasil-ditambahkan` frames: raises the
/// matching success modal over the Order home for ONE real delivery.
///
/// The order id is a path parameter, and required. The in-flow versions of
/// these modals are raised by `OrderDetailScreen`/`OrderScreen` from the
/// delivery the busboy just acted on, and `SuccessModal.details` has no
/// default precisely so a modal can never describe an order it doesn't have —
/// a deep link is no exception. An id that isn't on the board renders the same
/// not-found copy the detail screens use instead of an empty modal.
class _OrderSuccessRouteScreen extends ConsumerStatefulWidget {
  const _OrderSuccessRouteScreen({
    required this.orderId,
    required this.delivered,
  });

  final String orderId;

  /// False = `berhasil-ditambahkan` (just claimed, advances to Antar).
  /// True = `berhasil-ditambahkan-2` (just delivered, advances to Selesai).
  final bool delivered;

  @override
  ConsumerState<_OrderSuccessRouteScreen> createState() =>
      _OrderSuccessRouteScreenState();
}

class _OrderSuccessRouteScreenState
    extends ConsumerState<_OrderSuccessRouteScreen> {
  bool _raised = false;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(orderDetailProvider(widget.orderId));
    final boardAsync = ref.watch(orderBoardNotifierProvider);

    // The board is fetched asynchronously, so the order is only resolvable a
    // frame or more after this route builds — raise the modal on the first
    // build that actually has it, once.
    if (detail != null && !_raised) {
      _raised = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_show(detail));
      });
    }

    if (detail == null && !boardAsync.isLoading) {
      return const _OrderNotFound();
    }
    return const OrderScreen();
  }

  Future<void> _show(OrderDetail detail) {
    if (widget.delivered) {
      return showSuccessModal(
        context,
        title: DeliveredOrderCopy.title,
        message: DeliveredOrderCopy.message,
        confirmLabel: DeliveredOrderCopy.confirmLabel,
        details: deliveredOrderDetails(
          tableName: detail.tableName,
          customerName: detail.customerName,
        ),
        onConfirm: () => ref
            .read(orderTabProvider.notifier)
            .selectStatus(OrderStatus.selesai),
      );
    }
    return showSuccessModal(
      context,
      // Uses the SuccessModal frame defaults (Tugas Berhasil Diambil! …).
      details: claimedOrderDetails(
        tenantName: detail.tenantName,
        tableName: detail.tableName,
        location: detail.location,
        customerName: detail.customerName,
      ),
      onConfirm: () {
        ref.read(orderTabProvider.notifier).selectStatus(OrderStatus.antar);
        context.goNamed(AppRoutes.order);
      },
    );
  }
}

/// Shown when a success deep link names a delivery that is not on the board.
/// Same copy as the order detail screens.
class _OrderNotFound extends StatelessWidget {
  const _OrderNotFound();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Pesanan tidak ditemukan di daftar order.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// The post-login landing path for [role].
///
/// `data.user.role` is the routing signal, confirmed with the backend team:
/// [AuthRoles.tenantKeeper] lands on the tenant shell and [AuthRoles.busboy]
/// on the busboy shell.
///
/// Anything else — null, or a role the backend adds later — falls back to
/// [branchId], the signal the app used before roles were confirmed: a session
/// carrying a branch scope goes to the tenant shell, everything else to
/// busboy. That deliberately keeps an unrecognised role on whichever shell its
/// real scope data can actually serve, rather than guessing from a value this
/// build has never seen.
///
// TODO(open-question): a role whose required scope is missing (e.g.
// `tenant_keeper` with no branch scope) still lands on the tenant shell, where
// `TenantOrderBoard` throws and the screen shows the generic error copy. Only
// two roles are confirmed so far, so whether that should be rejected at login
// or surfaced as a dedicated screen is still open.
String homePathFor({required String? role, required String? branchId}) =>
    switch (role) {
      AuthRoles.tenantKeeper => TenantRoutes.orderPath,
      AuthRoles.busboy => AppRoutes.orderPath,
      _ => branchId != null ? TenantRoutes.orderPath : AppRoutes.orderPath,
    };

/// The single `GoRouter` for the whole app — one login route, and the
/// busboy and tenant bottom-nav shells mounted side by side (busboy at
/// `/order` etc., tenant under `/tenant/...` — see `TenantRoutes`). There is
/// no "app flavor" concept and no router per flavor: which shell a login
/// lands on is [homePathFor] of the session's role.
@riverpod
GoRouter appRouter(Ref ref) {
  final loggedIn = ref.watch(isLoggedInProvider);
  final homePath = homePathFor(
    role: ref.watch(sessionRoleProvider),
    branchId: ref.watch(sessionBranchIdProvider),
  );
  return GoRouter(
    // [isLoggedInProvider] and the session role are what let a successful
    // login land straight on the right shell's Order tab instead of the
    // login screen — see [homePath] above.
    initialLocation: loggedIn ? homePath : AppRoutes.loginPath,
    // Session expiry (401, via dioProvider's interceptor) clears
    // isLoggedInProvider mid-use; this guard makes that redirect to /login
    // on the next navigation, not only at the router's initial construction.
    redirect: (context, state) {
      final onLogin =
          state.matchedLocation == AppRoutes.loginPath ||
          state.matchedLocation.startsWith('${AppRoutes.loginPath}/');
      if (!loggedIn && !onLogin) return AppRoutes.loginPath;
      if (loggedIn && onLogin) return homePath;
      return null;
    },
    routes: [
      // Login sits OUTSIDE both shells (root navigator, no bottom nav).
      GoRoute(
        path: AppRoutes.loginPath,
        name: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Persistent 4-tab busboy bottom-nav shell.
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
                    path: 'detail/:orderId',
                    name: AppRoutes.orderDetail,
                    builder: (context, state) => OrderDetailScreen(
                      orderId: state.pathParameters['orderId']!,
                    ),
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
                  // berhasil-ditambahkan (modal): the claim confirmation.
                  // Primary UX raises it from the detail screen; this route is
                  // a deep-link entry for one real delivery.
                  GoRoute(
                    path: 'berhasil/:orderId',
                    name: AppRoutes.orderBerhasil,
                    builder: (context, state) => _OrderSuccessRouteScreen(
                      orderId: state.pathParameters['orderId']!,
                      delivered: false,
                    ),
                  ),
                  GoRoute(
                    path: 'selesai',
                    name: AppRoutes.orderSelesai,
                    builder: (context, state) =>
                        const _OrderTabDeepLink(status: OrderStatus.selesai),
                    routes: [
                      GoRoute(
                        path: 'detail/:orderId',
                        name: AppRoutes.orderSelesaiDetail,
                        builder: (context, state) => OrderSelesaiDetailScreen(
                          orderId: state.pathParameters['orderId']!,
                        ),
                      ),
                      // berhasil-ditambahkan-2 (modal): the delivered
                      // confirmation, same deep-link contract as above.
                      GoRoute(
                        path: 'berhasil/:orderId',
                        name: AppRoutes.orderSelesaiBerhasil,
                        builder: (context, state) => _OrderSuccessRouteScreen(
                          orderId: state.pathParameters['orderId']!,
                          delivered: true,
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
                    path: 'detail/:entryId',
                    name: AppRoutes.riwayatDetail,
                    builder: (context, state) => RiwayatDetailScreen(
                      entryId: state.pathParameters['entryId']!,
                    ),
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

      // Persistent 4-tab tenant bottom-nav shell — mounted under
      // `/tenant/...` (see `TenantRoutes`) alongside the busboy shell above.
      tenantShellRoute(),
    ],
  );
}

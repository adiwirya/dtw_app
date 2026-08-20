import 'package:dtw_app/app.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/tenant_board.dart';

/// The `/tenant/order` route (landed on post-login for a branch-scoped
/// session) hosts `TenantOrderScreen`, which reads the real, realtime-fed
/// `tenantOrderBoardProvider` — it needs a branch-scoped local storage, a
/// repository and a realtime service so the board's initial fetch resolves
/// instead of hanging on an unmocked platform channel (`flutter_secure_storage`
/// never replies in a widget test). An empty board is enough; this file
/// asserts tab wiring, not order rendering.
List<Override> _tenantBoardOverrides() =>
    tenantBoardOverrides(dio: cannedOrderListDio([]));

void main() {
  testWidgets('Tab switching changes the hosted tenant screen', (tester) async {
    // Tab switching is independent of auth — authenticate directly via the
    // providers so the redirect guard doesn't bounce back to /login. A
    // non-null `sessionBranchIdProvider` is what lands a login on the tenant
    // shell instead of the busboy one — see `core/flavor.dart`.
    final container = ProviderContainer(
      overrides: [
        sessionBranchIdProvider.overrideWith((ref) => 'branch-1'),
        ..._tenantBoardOverrides(),
      ],
    );
    addTearDown(container.dispose);
    container.read(isLoggedInProvider.notifier).state = true;

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await tester.pumpAndSettle();

    // Already lands on the Order tab (post-login, menu-order-baru).
    final router = GoRouter.of(tester.element(find.text('Order').first));

    // Order is active; the persistent 4-tab bottom nav is present with the
    // design labels (Order FAB / Menu / Laporan / Akun).
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/tenant/order',
    );
    expect(find.text('KFC\nFried Chicken'), findsOneWidget); // hosted screen
    expect(find.text('Order'), findsOneWidget); // nav label (FAB)
    expect(find.text('Menu'), findsOneWidget); // nav label
    expect(find.text('Laporan'), findsOneWidget); // nav label
    expect(find.text('Akun'), findsOneWidget); // nav label

    // Switch to Menu (→ menu-saya branch).
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/tenant/menu-saya',
    );

    // Switch to Laporan.
    await tester.tap(find.text('Laporan'));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/tenant/laporan',
    );

    // Switch to Akun (→ admin branch).
    await tester.tap(find.text('Akun'));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/tenant/admin',
    );

    // Back to Order.
    await tester.tap(find.text('Order'));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/tenant/order',
    );
  });
}

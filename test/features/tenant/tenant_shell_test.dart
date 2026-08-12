import 'package:dtw_app/app.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_login_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/tenant_board.dart';

Widget _bootTenant() => ProviderScope(
      overrides: [appFlavorProvider.overrideWith((ref) => AppFlavor.tenant)],
      child: const App(),
    );

/// The `/order` route (landed on post-login) hosts `TenantOrderScreen`, which
/// reads the real, realtime-fed `tenantOrderBoardProvider` — it needs a
/// branch-scoped local storage, a repository and a realtime service so the
/// board's initial fetch resolves instead of hanging on an unmocked platform
/// channel (`flutter_secure_storage` never replies in a widget test). An
/// empty board is enough; this file asserts tab wiring, not order rendering.
List<Override> _tenantBoardOverrides() =>
    tenantBoardOverrides(dio: cannedOrderListDio([]));

void main() {
  testWidgets('Tenant flavor boots on the login screen (outside the shell)',
      (tester) async {
    await tester.pumpWidget(_bootTenant());
    await tester.pumpAndSettle();

    // Login-default frame renders outside the shell → no bottom nav.
    expect(find.byType(TenantLoginScreen), findsOneWidget);
    expect(find.text('Masuk Sebagai'), findsOneWidget);
    expect(find.text('Menu Saya'), findsNothing);
    expect(find.text('Laporan'), findsNothing);
  });

  testWidgets('Tab switching changes the hosted tenant screen', (tester) async {
    // Tab switching is independent of auth — authenticate directly via the
    // provider so the redirect guard doesn't bounce back to /login.
    final container = ProviderContainer(
      overrides: [
        appFlavorProvider.overrideWith((ref) => AppFlavor.tenant),
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
    expect(router.routerDelegate.currentConfiguration.uri.path, '/order');
    expect(find.text('KFC\nFried Chicken'), findsOneWidget); // hosted screen
    expect(find.text('Order'), findsOneWidget); // nav label (FAB)
    expect(find.text('Menu'), findsOneWidget); // nav label
    expect(find.text('Laporan'), findsOneWidget); // nav label
    expect(find.text('Akun'), findsOneWidget); // nav label

    // Switch to Menu (→ menu-saya branch).
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/menu-saya');

    // Switch to Laporan.
    await tester.tap(find.text('Laporan'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/laporan');

    // Switch to Akun (→ admin branch).
    await tester.tap(find.text('Akun'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/admin');

    // Back to Order.
    await tester.tap(find.text('Order'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/order');
  });
}

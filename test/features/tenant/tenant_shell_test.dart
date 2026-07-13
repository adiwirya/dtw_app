import 'package:dtw_app/app.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_login_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _bootTenant() => ProviderScope(
      overrides: [appFlavorProvider.overrideWith((ref) => AppFlavor.tenant)],
      child: const App(),
    );

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
    await tester.pumpWidget(_bootTenant());
    await tester.pumpAndSettle();

    // Enter the shell — post-login lands on the Order tab (menu-order-baru).
    final router =
        GoRouter.of(tester.element(find.text('Masuk Sebagai')))
          ..go(TenantRoutes.orderPath);
    await tester.pumpAndSettle();

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

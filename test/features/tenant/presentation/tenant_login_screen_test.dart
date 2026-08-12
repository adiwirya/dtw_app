import 'package:dtw_app/app.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/auth/presentation/widgets/role_card.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/fake_local_storage.dart';
import '../../../support/fake_tenant_realtime_service.dart';

/// Minimal router exercising just the tenant login flow so navigation targets
/// (`tenantLoginTenant`) can be asserted without standing up the whole tenant
/// shell.
GoRouter _router() => GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          name: 'tenantLogin',
          builder: (_, _) => const TenantLoginScreen(),
          routes: [
            GoRoute(
              path: 'tenant',
              name: 'tenantLoginTenant',
              builder: (_, _) =>
                  const TenantLoginScreen(initialRole: LoginRole.tenan),
            ),
          ],
        ),
      ],
    );

Future<void> _pumpRouter(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: _router())),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'login-default renders header, role cards, Pilih Tenant and Masuk',
      (tester) async {
    await _pumpRouter(tester);

    expect(find.text('Masuk Sebagai'), findsOneWidget);
    expect(find.text('Tenant'), findsOneWidget);
    expect(find.text('Busboy'), findsOneWidget);
    // Tenant flavor adds the "Pilih Tenant" dropdown above Username.
    expect(find.text('Pilih Tenant'), findsWidgets);
    expect(find.text('Ingat Saya'), findsOneWidget);
    expect(find.text('Lupa Password ?'), findsOneWidget);
    expect(find.byType(PrimaryButton), findsOneWidget);
    // Default step: no card is selected yet.
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('tapping a role card on the default step reveals login-tenantt',
      (tester) async {
    await _pumpRouter(tester);

    await tester.tap(find.text('Tenant'));
    await tester.pumpAndSettle();

    // login-tenantt pre-selects Tenan -> the selected check badge appears.
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('login-tenantt step pre-selects the Tenan card', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TenantLoginScreen(initialRole: LoginRole.tenan),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RoleCard), findsNWidgets(2));
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  group('Masuk picks the flavor for the selected role (single shared entry)',
      () {
    Future<void> pumpTenantApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Boots straight into the tenant flavor (as if the shared login had
      // already switched here) so `TenantLoginScreen` is what's on screen.
      // `/order` (landed on post-"Masuk") hosts `TenantOrderScreen`, which
      // reads the real `tenantOrderBoardProvider` — without a fake local
      // storage the board's initial fetch hangs on an unmocked
      // `flutter_secure_storage` platform channel instead of resolving.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appFlavorProvider.overrideWith((ref) => AppFlavor.tenant),
            localStorageProvider.overrideWithValue(FakeLocalStorage()),
            tenantRealtimeServiceProvider
                .overrideWithValue(FakeTenantRealtimeService()),
          ],
          child: const App(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
        'no role selected defaults to tenan and lands on the tenant Order '
        'tab', (tester) async {
      await pumpTenantApp(tester);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // The real tenant Order home renders directly — no second login screen.
      expect(find.byType(TenantLoginScreen), findsNothing);
      expect(find.text('KFC\nFried Chicken'), findsOneWidget);
      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Laporan'), findsOneWidget);
    });

    testWidgets(
        'picking Busboy switches the whole app back to the busboy shell',
        (tester) async {
      await pumpTenantApp(tester);

      // Step 1 -> step 2 (always pre-selects Tenan); explicitly pick Busboy.
      await tester.tap(find.text('Busboy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Busboy'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // The real busboy Order home renders its Ambil/Antar/Selesai sub-tabs.
      expect(find.byType(TenantLoginScreen), findsNothing);
      expect(find.text('Ambil'), findsOneWidget);
      expect(find.text('Performa'), findsOneWidget);
    });
  });
}

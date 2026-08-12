import 'package:dtw_app/app.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/auth/presentation/screens/login_screen.dart';
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

  // "Masuk" used to fabricate a session outright: it set
  // `isLoggedInProvider = true` with no API call at all, so the app walked
  // straight into the tenant shell holding a token that was never issued.
  // That was invisible while the tenant flavor made no authenticated
  // requests; once the order board started calling the live API it became a
  // guaranteed 401. This screen now performs no authentication — it hands off
  // to the real, shared `LoginScreen` by resetting the flavor.
  group('Masuk hands off to the real login instead of faking a session', () {
    Future<ProviderContainer> pumpTenantApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Boots straight into the tenant flavor, the way `main_tenant.dart`
      // does, so `TenantLoginScreen` is what's on screen.
      final container = ProviderContainer(
        overrides: [
          appFlavorProvider.overrideWith((ref) => AppFlavor.tenant),
          localStorageProvider.overrideWithValue(FakeLocalStorage()),
          tenantRealtimeServiceProvider
              .overrideWithValue(FakeTenantRealtimeService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const App()),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('Masuk lands on the real busboy LoginScreen', (tester) async {
      final container = await pumpTenantApp(tester);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(container.read(appFlavorProvider), AppFlavor.busboy);
      expect(find.byType(TenantLoginScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Masuk does NOT log the user in', (tester) async {
      final container = await pumpTenantApp(tester);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // No credentials were ever checked, so no session may exist — and with
      // none, nothing from the tenant shell may be on screen.
      expect(container.read(isLoggedInProvider), isFalse);
      expect(find.text('KFC\nFried Chicken'), findsNothing);
      expect(find.text('Laporan'), findsNothing);
    });

    testWidgets('picking Busboy first reaches the same real login',
        (tester) async {
      final container = await pumpTenantApp(tester);

      // Step 1 -> step 2 (always pre-selects Tenan); explicitly pick Busboy.
      await tester.tap(find.text('Busboy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Busboy'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(container.read(isLoggedInProvider), isFalse);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}

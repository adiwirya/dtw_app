import 'package:dtw_app/app.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/auth/presentation/screens/login_screen.dart';
import 'package:dtw_app/features/auth/presentation/widgets/role_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Builds a minimal router exercising just the login flow so navigation
/// targets can be asserted without standing up the whole app shell.
GoRouter _router() => GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (_, _) => const LoginScreen(),
          routes: [
            GoRoute(
              path: 'tenant',
              name: 'loginTenant',
              builder: (_, _) =>
                  const LoginScreen(initialRole: LoginRole.busboy),
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
  testWidgets('login-default renders header, role cards and Masuk button',
      (tester) async {
    await _pumpRouter(tester);

    expect(find.text('Masuk Sebagai'), findsOneWidget);
    expect(find.text('Tenan'), findsOneWidget);
    expect(find.text('Busboy'), findsOneWidget);
    expect(find.text('Ingat Saya'), findsOneWidget);
    expect(find.text('Lupa Password ?'), findsOneWidget);
    expect(find.byType(PrimaryButton), findsOneWidget);
    // Default step: no card is selected yet.
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('tapping a role card on the default step reveals login-tenant',
      (tester) async {
    await _pumpRouter(tester);

    await tester.tap(find.text('Busboy'));
    await tester.pumpAndSettle();

    // login-tenant pre-selects Busboy -> the selected check badge appears.
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('login-tenant step pre-selects the Busboy card', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen(initialRole: LoginRole.busboy)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RoleCard), findsNWidgets(2));
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  group('Masuk picks the flavor for the selected role (single shared entry)',
      () {
    Future<void> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ProviderScope(child: App()));
      await tester.pumpAndSettle();
    }

    testWidgets(
        'no role selected defaults to busboy and lands on its Order tab',
        (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // The real busboy Order home renders its Ambil/Antar/Selesai sub-tabs.
      expect(find.text('Ambil'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      // Bottom nav confirms we're in the busboy shell, not the tenant one.
      expect(find.text('Performa'), findsOneWidget);
    });

    testWidgets('picking Tenan switches the whole app to the tenant shell',
        (tester) async {
      await pumpApp(tester);

      // Step 1 -> step 2 (always pre-selects Busboy); explicitly pick Tenan.
      await tester.tap(find.text('Tenan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tenan'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // The tenant Order home renders directly — no second login screen.
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('KFC\nFried Chicken'), findsOneWidget);
      // Tenant bottom nav labels confirm the flavor switch.
      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Laporan'), findsOneWidget);
    });
  });
}

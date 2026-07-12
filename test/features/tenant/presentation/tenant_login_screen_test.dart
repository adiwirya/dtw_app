import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/auth/presentation/widgets/role_card.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Minimal router exercising just the tenant login flow so navigation targets
/// (`tenantLoginTenant`, `tenantOrder`) can be asserted without standing up the
/// whole tenant shell.
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
        GoRoute(
          path: '/order',
          name: 'tenantOrder',
          builder: (_, _) => const Scaffold(body: Text('TENANT ORDER TAB')),
        ),
      ],
    );

void main() {
  testWidgets(
      'login-default renders header, role cards, Pilih Tenant and Masuk',
      (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await tester.pumpAndSettle();

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
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tenant'));
    await tester.pumpAndSettle();

    // login-tenantt pre-selects Tenan -> the selected check badge appears.
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('Masuk routes to the tenant Order tab', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(find.text('TENANT ORDER TAB'), findsOneWidget);
  });

  testWidgets('login-tenantt step pre-selects the Tenan card', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TenantLoginScreen(initialRole: LoginRole.tenan)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RoleCard), findsNWidgets(2));
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}

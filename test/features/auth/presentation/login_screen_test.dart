import 'package:dtw_app/app.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/auth/data/repositories/auth_repository.dart';
import 'package:dtw_app/features/auth/presentation/screens/login_screen.dart';
import 'package:dtw_app/features/auth/presentation/widgets/role_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/canned_dio.dart';
import '../../../support/fake_local_storage.dart';
import '../../../support/fake_tenant_realtime_service.dart';

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
    Future<ProviderContainer> pumpApp(
      WidgetTester tester, {
      required int statusCode,
      required Object? body,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final storage = FakeLocalStorage();
      final realtime = FakeTenantRealtimeService();
      addTearDown(realtime.close);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepository(dio: cannedDio(statusCode, body), localStorage: storage),
          ),
          tenantRealtimeServiceProvider.overrideWithValue(realtime),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const App()),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets(
        'no role selected defaults to busboy, calls the API, and lands on its Order tab',
        (tester) async {
      await pumpApp(
        tester,
        statusCode: 200,
        body: {
          'meta': {
            'success': true,
            'message': 'Success',
            'code': 200,
            'trace_id': 'abc',
          },
          'data': {
            'access_token': 'tok_123',
            'user': {'id': 'u1', 'username': 'budi'},
          },
        },
      );

      await tester.enterText(find.widgetWithText(AppInput, 'Username'), 'budi');
      await tester.enterText(find.widgetWithText(AppInput, 'Password'), 'secret');
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // The real busboy Order home renders its Ambil/Antar/Selesai sub-tabs.
      expect(find.text('Ambil'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      // Bottom nav confirms we're in the busboy shell, not the tenant one.
      expect(find.text('Performa'), findsOneWidget);
    });

    testWidgets('shows the mapped error message on a failed busboy login',
        (tester) async {
      await pumpApp(
        tester,
        statusCode: 401,
        body: {
          'meta': {
            'success': false,
            'message': 'Unauthorized',
            'code': 401,
            'trace_id': 'abc',
          },
          'errors': null,
        },
      );

      await tester.enterText(find.widgetWithText(AppInput, 'Username'), 'budi');
      await tester.enterText(find.widgetWithText(AppInput, 'Password'), 'wrong');
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('Username atau password salah.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets(
        'a branch-scoped login response lands on the tenant shell '
        'regardless of the tapped role card', (tester) async {
      await pumpApp(
        tester,
        statusCode: 200,
        body: {
          'meta': {
            'success': true,
            'message': 'Success',
            'code': 200,
            'trace_id': 'abc',
          },
          'data': {
            'access_token': 'tok_123',
            'user': {'id': 'u1', 'username': 'janji_jiwa_smlb'},
            'abilities': <dynamic>[],
            'scopes': [
              {'type': 'branch', 'tenant_branch_id': 'branch-1'},
            ],
          },
        },
      );

      // Tap Busboy (not Tenan) to prove the flavor comes from the response,
      // not from which role card was tapped.
      await tester.tap(find.text('Busboy'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(AppInput, 'Username'),
        'janji_jiwa_smlb',
      );
      await tester.enterText(
        find.widgetWithText(AppInput, 'Password'),
        'secret',
      );
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // The tenant Order home renders — no second login screen.
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('KFC\nFried Chicken'), findsOneWidget);
      // Tenant bottom nav labels confirm the flavor switch.
      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Laporan'), findsOneWidget);
    });

    testWidgets('tapping Tenan and submitting also calls the real API',
        (tester) async {
      await pumpApp(
        tester,
        statusCode: 401,
        body: {
          'meta': {
            'success': false,
            'message': 'Unauthorized',
            'code': 401,
            'trace_id': 'abc',
          },
          'errors': null,
        },
      );

      await tester.tap(find.text('Tenan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tenan'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(AppInput, 'Username'),
        'janji_jiwa_smlb',
      );
      await tester.enterText(
        find.widgetWithText(AppInput, 'Password'),
        'wrong',
      );
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // A real API call was made and its 401 error surfaced — today's stub
      // would have flipped straight to the tenant shell instead.
      expect(find.text('Username atau password salah.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}

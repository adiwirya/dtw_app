import 'package:dio/dio.dart';
import 'package:dtw_app/app.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/auth/data/repositories/auth_repository.dart';
import 'package:dtw_app/features/auth/presentation/screens/login_screen.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_order_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/canned_dio.dart';
import '../../../support/fake_local_storage.dart';
import '../../../support/fake_tenant_realtime_service.dart';
import '../../../support/tenant_board.dart';

/// Builds a minimal router exercising just the login flow so navigation
/// targets can be asserted without standing up the whole app shell.
GoRouter _router() => GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (_, _) => const LoginScreen(),
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
  testWidgets('renders header, form fields and the Masuk button',
      (tester) async {
    await _pumpRouter(tester);

    expect(find.widgetWithText(AppInput, 'Username'), findsOneWidget);
    expect(find.widgetWithText(AppInput, 'Password'), findsOneWidget);
    expect(find.text('Ingat Saya'), findsOneWidget);
    expect(find.text('Lupa Password ?'), findsOneWidget);
    expect(find.byType(PrimaryButton), findsOneWidget);
  });

  // There is only one login route/screen shared by both shells (see
  // `app_router.dart`) — the login response's `branch_id` is what decides
  // which shell (`sessionBranchIdProvider`, `core/flavor.dart`) a successful
  // login lands on, not a separate "app flavor".
  group('Masuk calls the real login API', () {
    Future<ProviderContainer> pumpApp(
      WidgetTester tester, {
      required int statusCode,
      required Object? body,
      FakeLocalStorage? storage,
      Dio? orderDio,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final resolvedStorage = storage ?? FakeLocalStorage();
      final realtime = FakeTenantRealtimeService();
      addTearDown(realtime.close);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepository(
              dio: cannedDio(statusCode, body),
              localStorage: resolvedStorage,
            ),
          ),
          localStorageProvider.overrideWithValue(resolvedStorage),
          tenantRealtimeServiceProvider.overrideWithValue(realtime),
          if (orderDio != null)
            tenantOrderRepositoryProvider.overrideWithValue(
              TenantOrderRepository(dio: orderDio),
            ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const App()),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('a successful response lands on the busboy Order tab',
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
      await tester.enterText(
        find.widgetWithText(AppInput, 'Password'),
        'secret',
      );
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // The real busboy Order home renders its Ambil/Antar/Selesai sub-tabs.
      expect(find.text('Ambil'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      // Bottom nav confirms we're in the busboy shell, not the tenant one.
      expect(find.text('Performa'), findsOneWidget);
    });

    testWidgets('a branch-scoped response lands on the tenant shell',
        (tester) async {
      await pumpApp(
        tester,
        statusCode: 200,
        orderDio: cannedOrderListDio([]),
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
              {'type': 'branch', 'tenant_branch_id': testBranchId},
            ],
          },
        },
      );

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
      // Tenant bottom nav labels confirm we landed on the tenant shell.
      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Laporan'), findsOneWidget);
    });

    testWidgets('shows the mapped error message on a failed login',
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
      await tester.enterText(
        find.widgetWithText(AppInput, 'Password'),
        'wrong',
      );
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('Username atau password salah.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('empty username/password shows a validation message and '
        'makes no API call', (tester) async {
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

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('Username dan password wajib diisi.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}

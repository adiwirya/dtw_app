import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/akun/presentation/screens/akun_screen.dart';
import 'package:dtw_app/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/canned_dio.dart';
import '../../../support/fake_local_storage.dart';

GoRouter _testRouter() => GoRouter(
      initialLocation: '/akun',
      routes: [
        GoRoute(
          path: '/akun',
          name: AppRoutes.akun,
          builder: (context, state) => const AkunScreen(),
          routes: [
            GoRoute(
              path: 'profile',
              name: AppRoutes.akunProfile,
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('PROFILE SAYA SCREEN')),
              ),
            ),
          ],
        ),
      ],
    );

Future<void> _pump(
  WidgetTester tester,
  GoRouter router, {
  String? username = 'busboy1',
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sessionUsernameProvider.overrideWith((ref) => username)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the identity, stats and every menu row', (tester) async {
    await _pump(tester, _testRouter());

    // The greeting is the real session username — not a fabricated name.
    expect(find.text('Hi, busboy1'), findsOneWidget);
    // No busboy-profile endpoint yet, so identity/stats show a placeholder
    // rather than a fabricated ID/date/number.
    expect(find.text('Busboy ID : -'), findsOneWidget);
    expect(find.text('Bergabung -'), findsOneWidget);

    // Stats box.
    expect(find.text('Tugas Selesai'), findsOneWidget);
    expect(find.text('Rating Pelanggan'), findsOneWidget);

    // Menu rows + logout.
    for (final title in const [
      'Profil Saya',
      'Ubah Kata Sandi',
      'Bahasa',
      'Bantuan & FAQ',
      'Kebijakan Privasi',
      'Keluar',
    ]) {
      expect(find.text(title), findsOneWidget, reason: 'missing row: $title');
    }
  });

  testWidgets('omits the name from the greeting when the username is unknown',
      (tester) async {
    await _pump(tester, _testRouter(), username: null);

    expect(find.text('Hi'), findsOneWidget);
    expect(find.textContaining('Hi,'), findsNothing);
  });

  testWidgets('tapping Profil Saya navigates to the akunProfile route',
      (tester) async {
    await _pump(tester, _testRouter());

    expect(find.text('PROFILE SAYA SCREEN'), findsNothing);

    await tester.tap(find.text('Profil Saya'));
    await tester.pumpAndSettle();

    expect(find.text('PROFILE SAYA SCREEN'), findsOneWidget);
  });

  testWidgets('tapping Keluar logs out and clears isLoggedInProvider',
      (tester) async {
    final storage = FakeLocalStorage()..values[authTokenStorageKey] = 'tok_123';
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          AuthRepository(
            dio: cannedDio(200, {
              'meta': {
                'success': true,
                'message': 'Success',
                'code': 200,
                'trace_id': 'abc',
              },
            }),
            localStorage: storage,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(isLoggedInProvider.notifier).state = true;

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: _testRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();

    expect(container.read(isLoggedInProvider), isFalse);
  });
}

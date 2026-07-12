import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/features/akun/presentation/screens/akun_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: router)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the identity, stats and every menu row', (tester) async {
    await _pump(tester, _testRouter());

    expect(find.text('Hi, Adi Wiryadi'), findsOneWidget);
    expect(find.text('Busboy ID : BBY-0123'), findsOneWidget);
    expect(find.text('Bergabung 12 Januari 2024'), findsOneWidget);

    // Stats box.
    expect(find.text('542'), findsOneWidget);
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

  testWidgets('tapping Profil Saya navigates to the akunProfile route',
      (tester) async {
    await _pump(tester, _testRouter());

    expect(find.text('PROFILE SAYA SCREEN'), findsNothing);

    await tester.tap(find.text('Profil Saya'));
    await tester.pumpAndSettle();

    expect(find.text('PROFILE SAYA SCREEN'), findsOneWidget);
  });
}

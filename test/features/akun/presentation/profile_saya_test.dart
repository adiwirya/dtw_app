import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/features/akun/presentation/screens/akun_screen.dart';
import 'package:dtw_app/features/akun/presentation/screens/profile_saya_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:obra_icons/obra_icons.dart';

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
              builder: (context, state) => const ProfileSayaScreen(),
            ),
          ],
        ),
      ],
    );

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  tester.view.physicalSize = const Size(390, 1083);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: router)),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1083);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sessionUsernameProvider.overrideWith((ref) => 'busboy1')],
      child: const MaterialApp(home: ProfileSayaScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the profile fields, real username + placeholders',
      (tester) async {
    await _pumpScreen(tester);

    // Nav bar + section titles.
    expect(find.text('Profile Saya'), findsOneWidget);
    expect(find.text('Informasi Pribadi'), findsOneWidget);
    expect(find.text('Informasi Pekerjaan'), findsOneWidget);

    // Photo-upload caption.
    expect(find.text('JPG, PNG Maksimal 2 MB'), findsOneWidget);

    // Field labels.
    for (final label in const [
      'Busboy ID',
      'Nama Lengkap',
      'No. Telepon',
      'Outlet / Lokasi',
      'Shift',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'missing label: $label');
    }

    // The real session username fills Nama Lengkap; every other field has no
    // backing endpoint yet, so it shows a placeholder rather than a
    // fabricated value.
    expect(find.text('busboy1'), findsOneWidget);
    // Busboy ID, No. Telepon, Email, Outlet / Lokasi, Shift.
    expect(find.text('-'), findsNWidgets(5));

    // The CTA.
    expect(find.text('Simpan'), findsOneWidget);
  });

  testWidgets('Simpan shows the mock-save confirmation', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.text('Perubahan disimpan (mock)'), findsOneWidget);
  });

  testWidgets('back arrow returns to the Akun screen', (tester) async {
    // Navigate in from Akun so the profile route is poppable.
    final router = _testRouter()..goNamed(AppRoutes.akunProfile);
    await _pump(tester, router);

    expect(find.byType(ProfileSayaScreen), findsOneWidget);

    await tester.tap(find.byIcon(ObraIcons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.byType(AkunScreen), findsOneWidget);
    expect(find.byType(ProfileSayaScreen), findsNothing);
  });
}

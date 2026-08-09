import 'package:dtw_app/app.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('App boots on the login screen (outside the shell)',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    // The real login-default screen renders the "Masuk Sebagai" role picker.
    expect(find.text('Masuk Sebagai'), findsOneWidget);
    // No bottom nav while outside the shell.
    expect(find.text('Performa'), findsNothing);
    expect(find.text('Riwayat'), findsNothing);
  });

  testWidgets('Tab switching changes the hosted screen', (tester) async {
    // Tab switching is independent of auth — authenticate directly via the
    // provider so the redirect guard doesn't bounce back to /login.
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(isLoggedInProvider.notifier).state = true;

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await tester.pumpAndSettle();

    // Already lands on the Order tab (post-login). Use a context below the
    // Router so GoRouter.of can resolve it.
    final router = GoRouter.of(tester.element(find.text('Ambil').first));

    // Order is the active screen and the bottom nav is present. The real
    // menu-order screen renders its Ambil / Antar / Selesai sub-tabs.
    expect(find.text('Ambil'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Performa'), findsOneWidget); // nav label

    // Switch to Performa.
    await tester.tap(find.text('Performa'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/performa');
    // The real Performa dashboard (performa-v1) renders this section heading.
    expect(find.text('Ringkasan Performa'), findsOneWidget);

    // Switch to Riwayat.
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/riwayat');
    // The real Riwayat home renders its date tabs and search affordance.
    expect(find.text('Hari Ini'), findsOneWidget);
    expect(find.text('Cari riwayat...'), findsOneWidget);

    // Switch to Akun.
    await tester.tap(find.text('Akun'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/akun');
  });
}

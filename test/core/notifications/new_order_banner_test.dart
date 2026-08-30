import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/notifications/new_order_alert.dart';
import 'package:dtw_app/core/notifications/new_order_alert_controller.dart';
import 'package:dtw_app/core/notifications/new_order_alerts.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/widgets/new_order_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_new_order_alerts.dart';
import '../../support/fake_tenant_realtime_service.dart';
import '../../support/tenant_board.dart';

const _alert = NewOrderAlert(
  orderId: 'order-1',
  title: 'Orderan Baru Masuk',
  body: 'Meja A-12 · 3 item · Rp45.000',
);

/// Pumps the overlay above a stand-in "somewhere else in the app" screen with
/// a tappable body, so a test can prove taps still reach it.
Future<FakeTenantRealtimeService> _pump(
  WidgetTester tester, {
  List<String>? tapped,
}) async {
  final realtime = FakeTenantRealtimeService();
  addTearDown(realtime.close);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: GestureDetector(
            // `deferToChild` (the default) only registers a tap that lands on
            // the child itself, which here is centred text.
            behavior: HitTestBehavior.opaque,
            onTap: () => tapped?.add('behind'),
            child: const SizedBox.expand(
              child: Align(child: Text('Menu Saya')),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/order',
        name: TenantRoutes.order,
        builder: (_, _) => const Scaffold(body: Text('Layar Order')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // The overlay navigates through this instance rather than through an
        // inherited lookup, which cannot work from `MaterialApp.builder`.
        appRouterProvider.overrideWithValue(router),
        sessionRoleProvider.overrideWith((ref) => AuthRoles.tenantKeeper),
        sessionBranchIdProvider.overrideWith((ref) => testBranchId),
        tenantRealtimeServiceProvider.overrideWithValue(realtime),
        newOrderAlertsProvider.overrideWithValue(FakeNewOrderAlerts()),
        appLifecycleProvider.overrideWithValue(() => AppLifecycleState.resumed),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) =>
            NewOrderBannerOverlay(child: child ?? const SizedBox.shrink()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return realtime;
}

ProviderContainer _container(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.text('Menu Saya')),
);

void main() {
  testWidgets('shows nothing until an order arrives', (tester) async {
    await _pump(tester);

    expect(find.byType(NewOrderBanner), findsNothing);
  });

  // The overlay is mounted over every screen for the whole session; if it
  // hit-tested while idle it would break the app rather than decorate it.
  testWidgets('an idle overlay does not swallow taps', (tester) async {
    final tapped = <String>[];
    await _pump(tester, tapped: tapped);

    // Tap right where the banner would be, at the very top of the screen.
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();

    expect(tapped, ['behind']);
  });

  testWidgets('drops in on any screen, not just the order tab', (tester) async {
    await _pump(tester);
    // Still on the Menu Saya stand-in.
    expect(find.text('Menu Saya'), findsOneWidget);

    _container(tester).read(newOrderAlertBannerProvider.notifier).show(_alert);
    await tester.pumpAndSettle();

    expect(find.text('Orderan Baru Masuk'), findsOneWidget);
    expect(find.text('Meja A-12 · 3 item · Rp45.000'), findsOneWidget);
  });

  testWidgets('a real order.created event raises it', (tester) async {
    final realtime = await _pump(tester);

    realtime.emitOrderCreated(
      tenantOrderJson(
        id: 'order-9',
        status: 'PENDING',
        tableNumber: 'B-03',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meja B-03 · Rp21.000'), findsOneWidget);
  });

  testWidgets('tapping it opens the order screen and clears the banner', (
    tester,
  ) async {
    await _pump(tester);
    _container(tester).read(newOrderAlertBannerProvider.notifier).show(_alert);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lihat'));
    await tester.pumpAndSettle();

    expect(find.text('Layar Order'), findsOneWidget);
    expect(find.byType(NewOrderBanner), findsNothing);
  });

  testWidgets('swiping up dismisses it', (tester) async {
    await _pump(tester);
    _container(tester).read(newOrderAlertBannerProvider.notifier).show(_alert);
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(NewOrderBanner),
      const Offset(0, -200),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.byType(NewOrderBanner), findsNothing);
    // Still on the screen it interrupted — dismissing is not opening.
    expect(find.text('Menu Saya'), findsOneWidget);
  });

  testWidgets('it gets out of the way on its own', (tester) async {
    await _pump(tester);
    _container(tester).read(newOrderAlertBannerProvider.notifier).show(_alert);
    await tester.pumpAndSettle();
    expect(find.byType(NewOrderBanner), findsOneWidget);

    await tester.pump(NewOrderAlertBanner.visibleFor);
    await tester.pumpAndSettle();

    expect(find.byType(NewOrderBanner), findsNothing);
  });
}

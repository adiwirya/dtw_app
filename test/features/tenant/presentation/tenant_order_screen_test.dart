import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_order_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/tenant_board.dart';

/// Pumps [TenantOrderScreen] inside a minimal router, with the order board
/// backed by a canned repository seeded with 2 pending, 1 preparing, 1 ready
/// order (matching the old mock's Baru/Diproses/Selesai split) so the
/// existing sub-tab assertions stay meaningful.
///
/// Returns the router so a test can assert where a card action navigated to.
Future<GoRouter> _pumpScreen(
  WidgetTester tester, {
  IncomingOrderStatus initialStatus = IncomingOrderStatus.baru,
}) async {
  final dio = cannedOrderListDio([
    tenantOrderJson(id: '1', status: 'PENDING'),
    tenantOrderJson(id: '2', status: 'PENDING'),
    tenantOrderJson(id: '3', status: 'PREPARING'),
    tenantOrderJson(id: '4', status: 'READY'),
  ]);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            TenantOrderScreen(initialStatus: initialStatus),
      ),
      // Mirrors the real route's `:orderId` path parameter so a navigation
      // that forgot to pass the id would throw here instead of quietly
      // landing on a screen with no order.
      GoRoute(
        path: '/ditolak/:orderId',
        name: TenantRoutes.pesananDitolak,
        builder: (context, state) =>
            Text('ditolak:${state.pathParameters['orderId']}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: tenantBoardOverrides(dio: dio),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  group('TenantOrderScreen in-place status sub-filtering', () {
    testWidgets('starts on Order Baru and lists only baru orders',
        (tester) async {
      await _pumpScreen(tester);

      expect(find.byType(IncomingOrderCard), findsNWidgets(2));
      expect(find.text('Terima'), findsNWidgets(2));
      expect(find.text('Tolak'), findsNWidgets(2));
      expect(find.text('RCP-1'), findsOneWidget);
      expect(find.text('RCP-2'), findsOneWidget);
      expect(find.text('Siap Diambil'), findsNothing);
    });

    testWidgets('tapping Diproses switches the list in place', (tester) async {
      await _pumpScreen(tester);

      await tester.tap(find.text('Diproses'));
      await tester.pumpAndSettle();

      expect(find.byType(IncomingOrderCard), findsOneWidget);
      expect(find.text('Siap Diambil'), findsOneWidget);
      expect(find.text('Terima'), findsNothing);
    });

    testWidgets('tapping Selesai shows completed orders with no actions',
        (tester) async {
      await _pumpScreen(tester);

      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(find.byType(IncomingOrderCard), findsOneWidget);
      expect(find.text('Siap Diambil'), findsNothing);
      expect(find.text('Terima'), findsNothing);
      expect(find.text('Tolak'), findsNothing);
    });

    testWidgets('initialStatus seeds the diproses sub-tab (menu-diproses)',
        (tester) async {
      await _pumpScreen(tester, initialStatus: IncomingOrderStatus.diproses);

      expect(find.text('Siap Diambil'), findsOneWidget);
      expect(find.text('Terima'), findsNothing);
    });
  });

  group('reject navigation', () {
    // Regression test: "Tolak" used to navigate with NO order id, so the
    // reject screen fell back to a hardcoded placeholder and its confirm
    // silently no-oped. The id of the tapped card must reach the route.
    testWidgets('Tolak carries the tapped order id into the route',
        (tester) async {
      final router = await _pumpScreen(tester);

      await tester.tap(find.text('Tolak').first);
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/ditolak/1',
      );
      expect(find.text('ditolak:1'), findsOneWidget);
    });

    testWidgets("Tolak on the second card carries that card's id",
        (tester) async {
      final router = await _pumpScreen(tester);

      await tester.tap(find.text('Tolak').last);
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/ditolak/2',
      );
    });
  });
}

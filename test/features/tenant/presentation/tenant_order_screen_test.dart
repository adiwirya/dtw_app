import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_order_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Pumps [TenantOrderScreen] inside a minimal router so the `Tolak` navigation
/// callback has a `context.goNamed` target.
Future<void> _pumpScreen(
  WidgetTester tester, {
  IncomingOrderStatus initialStatus = IncomingOrderStatus.baru,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            TenantOrderScreen(initialStatus: initialStatus),
      ),
      GoRoute(
        path: '/ditolak',
        name: TenantRoutes.pesananDitolak,
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('TenantOrderScreen in-place status sub-filtering', () {
    testWidgets('starts on Order Baru and lists only baru orders',
        (tester) async {
      await _pumpScreen(tester);

      // Two baru cards; both show the "Terima (29s)" accept action.
      expect(find.byType(IncomingOrderCard), findsNWidgets(2));
      expect(find.text('Terima (29s)'), findsNWidgets(2));
      expect(find.text('Tolak'), findsNWidgets(2));
      expect(find.text('Meja A-12'), findsOneWidget);
      expect(find.text('Meja A-14'), findsOneWidget);
      // No diproses/selesai affordances yet.
      expect(find.text('Siap Diambil'), findsNothing);
    });

    testWidgets('tapping Diproses switches the list in place', (tester) async {
      await _pumpScreen(tester);

      await tester.tap(find.text('Diproses'));
      await tester.pumpAndSettle();

      expect(find.byType(IncomingOrderCard), findsOneWidget);
      expect(find.text('Siap Diambil'), findsOneWidget);
      expect(find.text('Terima (29s)'), findsNothing);
    });

    testWidgets('tapping Selesai shows completed orders with no actions',
        (tester) async {
      await _pumpScreen(tester);

      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(find.byType(IncomingOrderCard), findsOneWidget);
      expect(find.text('Siap Diambil'), findsNothing);
      expect(find.text('Terima (29s)'), findsNothing);
      expect(find.text('Tolak'), findsNothing);
    });

    testWidgets('initialStatus seeds the diproses sub-tab (menu-diproses)',
        (tester) async {
      await _pumpScreen(tester, initialStatus: IncomingOrderStatus.diproses);

      expect(find.text('Siap Diambil'), findsOneWidget);
      expect(find.text('Terima (29s)'), findsNothing);
    });
  });
}

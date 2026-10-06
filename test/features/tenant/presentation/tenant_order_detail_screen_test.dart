import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_order_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:obra_icons/obra_icons.dart';

import '../../../support/fake_receipt_printer_service.dart';
import '../../../support/tenant_board.dart';

/// Pumps the real [TenantOrderDetailScreen] for [orderId], backed by a board
/// seeded with [orders]. Sibling routes just echo where a navigation landed.
Future<GoRouter> _pump(
  WidgetTester tester, {
  required List<Map<String, dynamic>> orders,
  String orderId = '1',
  FakeReceiptPrinterService? printer,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/detail/$orderId',
    routes: [
      GoRoute(
        path: '/',
        name: TenantRoutes.order,
        builder: (_, _) => const Text('order-home'),
      ),
      GoRoute(
        path: '/detail/:orderId',
        name: TenantRoutes.orderDetail,
        builder: (_, state) => TenantOrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: '/ditolak/:orderId',
        name: TenantRoutes.pesananDitolak,
        builder: (_, state) =>
            Text('ditolak:${state.pathParameters['orderId']}'),
      ),
      GoRoute(
        path: '/verifikasi/:orderId',
        name: TenantRoutes.verifikasiPickup,
        builder: (_, state) =>
            Text('verifikasi:${state.pathParameters['orderId']}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: tenantBoardOverrides(
        dio: cannedOrderListDio(orders),
        printer: printer,
      ),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

Map<String, dynamic> _order({
  String id = '1',
  String status = 'PENDING',
  String? customerName = 'Budi Santoso',
  bool? isDelivery = true,
}) => tenantOrderJson(
  id: id,
  status: status,
  tableNumber: 'A-12',
  customerName: customerName,
  isDelivery: isDelivery,
  grandTotal: 40000,
  items: [
    tenantOrderItemJson(
      id: 'i1',
      productName: 'Paket Super Besar',
      subtotal: 35000,
    ),
    tenantOrderItemJson(
      id: 'i2',
      productName: 'Es Lemon Tea',
      subtotal: 5000,
      notes: 'Tanpa es',
    ),
  ],
);

void main() {
  group('content', () {
    testWidgets('shows the order, table, customer and summary', (tester) async {
      await _pump(tester, orders: [_order()]);

      expect(find.text('Detail Pesanan'), findsOneWidget);
      expect(find.text('#RCP-1'), findsOneWidget);
      expect(find.text('KFC Fried Chicken'), findsOneWidget);
      expect(find.text('Meja A-12'), findsOneWidget);
      expect(find.text('Delivery'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Ringkasan Pesanan'), findsOneWidget);
      expect(find.text('Paket Super Besar'), findsOneWidget);
      expect(find.text('Rp40.000'), findsOneWidget);
      expect(find.text('Ambil Pesanan'), findsNothing);
    });

    testWidgets('shows a dash when the API sends no customer name', (
      tester,
    ) async {
      await _pump(tester, orders: [_order(customerName: null)]);

      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('has no call button — there is no phone number to call', (
      tester,
    ) async {
      await _pump(tester, orders: [_order()]);

      expect(find.byIcon(ObraIcons.phone), findsNothing);
    });

    testWidgets('shows each item note, or "Tidak ada catatan"', (tester) async {
      await _pump(tester, orders: [_order()]);

      expect(find.text('Tanpa es'), findsOneWidget);
      expect(find.text('Tidak ada catatan'), findsOneWidget);
    });

    testWidgets('an unknown order id says so', (tester) async {
      await _pump(tester, orders: [_order()], orderId: 'nope');

      expect(find.text('Pesanan tidak ditemukan.'), findsOneWidget);
    });
  });

  group('bottom actions follow the Order menu', () {
    testWidgets('Baru shows Tolak and Terima', (tester) async {
      await _pump(tester, orders: [_order()]);

      expect(find.text('Tolak'), findsOneWidget);
      expect(find.text('Terima'), findsOneWidget);
    });

    testWidgets(
      'Terima accepts, prints the bon and returns to the Order list',
      (tester) async {
        final printer = FakeReceiptPrinterService();
        final router = await _pump(
          tester,
          orders: [_order()],
          printer: printer,
        );

        await tester.tap(find.text('Terima'));
        await tester.pumpAndSettle();

        expect(printer.printed, hasLength(1));
        expect(printer.printed.single.order.id, '1');
        expect(_path(router), '/');
      },
    );

    testWidgets('Tolak opens the reject screen for this order', (tester) async {
      final router = await _pump(tester, orders: [_order()]);

      await tester.tap(find.text('Tolak'));
      await tester.pumpAndSettle();

      expect(_path(router), '/ditolak/1');
    });

    testWidgets('Diproses shows only Siap Diambil, which returns to the list', (
      tester,
    ) async {
      final router = await _pump(
        tester,
        orders: [_order(status: 'PREPARING')],
      );

      expect(find.text('Terima'), findsNothing);
      expect(find.text('Tolak'), findsNothing);

      await tester.tap(find.text('Siap Diambil'));
      await tester.pumpAndSettle();

      expect(_path(router), '/');
    });

    testWidgets('a ready self-pickup order shows Verifikasi Pickup', (
      tester,
    ) async {
      final router = await _pump(
        tester,
        orders: [_order(status: 'READY', isDelivery: false)],
      );

      expect(find.text('Siap Diambil'), findsNothing);

      await tester.tap(find.text('Verifikasi Pickup'));
      await tester.pumpAndSettle();

      expect(_path(router), '/verifikasi/1');
    });

    testWidgets('Selesai has no action bar', (tester) async {
      await _pump(tester, orders: [_order(status: 'COMPLETED')]);

      expect(find.text('Terima'), findsNothing);
      expect(find.text('Tolak'), findsNothing);
      expect(find.text('Siap Diambil'), findsNothing);
      expect(find.text('Verifikasi Pickup'), findsNothing);
    });
  });
}

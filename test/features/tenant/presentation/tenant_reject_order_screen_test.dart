import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/app_toggle.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_order_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_reject_order_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/canned_dio.dart';
import '../../../support/tenant_board.dart';

/// The one order on the board in these tests.
const _orderId = 'order-1';

/// The bottom confirm CTA. [PrimaryButton] carries its enabled state as a
/// nullable `onPressed`, so tests assert on that rather than on pixels.
PrimaryButton _confirmButton(WidgetTester tester) =>
    tester.widget<PrimaryButton>(find.byType(PrimaryButton));

/// Hosts the reject screen in a minimal router so `context.goNamed(...)`
/// targets (pesanan-diproses) resolve and the success modal can push/pop.
///
/// [orderId] is what the screen is asked to reject; point it at something not
/// in the seeded board to exercise the not-found path. The returned
/// [CannedAdapter] records the last request, so a test can prove the
/// rejection actually reached `PATCH /v1/orders/{id}/status` rather than
/// stopping at a success modal.
Future<CannedAdapter> _pump(
  WidgetTester tester, {
  String orderId = _orderId,
  String? initialReason,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final dio = cannedOrderListDio([
    tenantOrderJson(
      id: _orderId,
      status: 'PENDING',
      grandTotal: 40000,
      receiptNumber: 'RCP-92842',
      createdAt: '2024-05-10 10:36:00',
    ),
  ]);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => TenantRejectOrderScreen(
          orderId: orderId,
          initialReason: initialReason,
        ),
      ),
      GoRoute(
        path: '/diproses',
        name: TenantRoutes.pesananDiproses,
        builder: (context, state) => const TenantOrderScreen(
          initialStatus: IncomingOrderStatus.diproses,
        ),
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
  return dio.httpClientAdapter as CannedAdapter;
}

void main() {
  testWidgets('formatRupiah groups thousands with a dot', (_) async {
    expect(formatRupiah(35000), 'Rp35.000');
    expect(formatRupiah(5000), 'Rp5.000');
    expect(formatRupiah(1234567), 'Rp1.234.567');
    expect(formatRupiah(0), 'Rp0');
  });

  testWidgets('renders the real order off the board, not seeded mock data',
      (tester) async {
    await _pump(tester);

    expect(find.text('Tolak Pesanan'), findsOneWidget);
    expect(find.text('#$_orderId'), findsOneWidget);
    // Receipt number + formatted createdAt come from the board entry.
    expect(find.text('RCP-92842'), findsOneWidget);
    expect(find.text('10 Mei 2024 10:36 WIB'), findsOneWidget);
    // The order total, not a recomputed "accepted" subtotal.
    expect(find.text('Rp40.000'), findsOneWidget);
    // The old hardcoded mock items and order number are gone.
    expect(find.text('#92842'), findsNothing);
    expect(find.text('Paket Super Besar'), findsNothing);
    expect(find.text('Es Lemon Tea'), findsNothing);
  });

  group('all-or-nothing rejection (no partial fulfillment)', () {
    testWidgets('offers no per-item availability toggles', (tester) async {
      await _pump(tester);

      expect(find.byType(AppToggle), findsNothing);
      expect(find.byType(OrderItemAvailabilityRow), findsNothing);
      expect(find.text('Tersedia'), findsNothing);
      expect(find.text('Daftar Item'), findsNothing);
    });

    testWidgets('copy says the whole order is cancelled', (tester) async {
      await _pump(tester);

      expect(find.text(wholeOrderRejectionTitle), findsOneWidget);
      expect(find.text(wholeOrderRejectionBody), findsOneWidget);
      expect(find.text(rejectOrderConfirmLabel), findsOneWidget);
      // The old partial-fulfillment promises.
      expect(find.text('Anda dapat menolak sebagian item'), findsNothing);
      expect(
        find.text('Pelanggan tetap akan menerima item yang tersedia'),
        findsNothing,
      );
    });
  });

  group('reason capture', () {
    testWidgets('confirm is disabled until a reason is given', (tester) async {
      await _pump(tester);

      expect(_confirmButton(tester).onPressed, isNull);

      await tester.tap(find.text('Stok Habis'));
      await tester.pumpAndSettle();

      expect(_confirmButton(tester).onPressed, isNotNull);
    });

    testWidgets('a free-text reason overrides the selected preset',
        (tester) async {
      final adapter = await _pump(tester);

      await tester.tap(find.text('Stok Habis'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(AppInput, 'Alasan Lainnya'),
        'Kompor rusak',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(rejectOrderConfirmLabel));
      await tester.pumpAndSettle();

      expect(adapter.lastRequest?.data, {
        'order_status': 'CANCELLED',
        'reason': 'Kompor rusak',
      });
    });

    testWidgets('konfirmasi deep-link seeds the chosen-reason state',
        (tester) async {
      await _pump(tester, initialReason: 'Stok Habis');

      expect(_confirmButton(tester).onPressed, isNotNull);
    });
  });

  group('confirm flow', () {
    // The regression test for the silent-failure bug: rejecting an order that
    // IS on the board has to actually PATCH the backend.
    testWidgets('confirming an order on the board calls updateStatus',
        (tester) async {
      final adapter = await _pump(tester, initialReason: 'Stok Habis');

      await tester.tap(find.text(rejectOrderConfirmLabel));
      await tester.pumpAndSettle();

      expect(adapter.lastRequest?.method, 'PATCH');
      expect(
        adapter.lastRequest?.path,
        '/v1/orders/$_orderId/status',
      );
      expect(adapter.lastRequest?.data, {
        'order_status': 'CANCELLED',
        'reason': 'Stok Habis',
      });
    });

    testWidgets('a successful rejection raises the rejected modal → Diproses',
        (tester) async {
      await _pump(tester, initialReason: 'Stok Habis');

      await tester.tap(find.text(rejectOrderConfirmLabel));
      await tester.pumpAndSettle();

      expect(find.text(rejectedOrderModalTitle), findsOneWidget);
      // No accepted-vs-rejected breakdown — nothing was accepted.
      expect(find.text('1 item diterima'), findsNothing);

      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();
      expect(find.byType(TenantOrderScreen), findsOneWidget);
    });

    // The other half of the regression: an order id that is NOT on the board
    // must never reach a success modal. It used to, because the board's
    // `_transition` returned silently on an unknown id.
    testWidgets('an order id not on the board surfaces not-found, no confirm',
        (tester) async {
      final adapter = await _pump(tester, orderId: 'ghost-order');

      expect(find.text(orderNotFoundMessage), findsOneWidget);
      // No confirm affordance at all, so no way to fake a success.
      expect(find.text(rejectOrderConfirmLabel), findsNothing);
      expect(find.text(rejectedOrderModalTitle), findsNothing);
      // Only the board's own GET happened — nothing was PATCHed.
      expect(adapter.lastRequest?.method, 'GET');
    });
  });
}

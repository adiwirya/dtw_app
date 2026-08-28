import 'package:dtw_app/core/router/tenant_router.dart';
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
/// rejection actually reached `POST /v1/orders/{id}/process` rather than
/// stopping at a success modal.
Future<CannedAdapter> _pump(
  WidgetTester tester, {
  String orderId = _orderId,
  bool seedFirstItemRejected = false,
}) async {
  // Taller than the app's real 390x844: with the rejected-items banner
  // showing, the item list + bottom summary no longer both fit a phone-size
  // viewport, and `ListView`'s sliver virtualization then treats a
  // below-the-fold row as offstage — invisible to `find`, even though it's
  // mounted. The extra height keeps every row reachable without scrolling.
  tester.view.physicalSize = const Size(390, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final dio = cannedOrderListDio([
    tenantOrderJson(
      id: _orderId,
      status: 'PENDING',
      grandTotal: 40000,
      receiptNumber: 'RCP-92842',
      createdAt: '2024-05-10 10:36:00',
      items: [
        tenantOrderItemJson(
          id: 'item-1',
          productName: 'Paket Super Besar',
          subtotal: 35000,
        ),
        tenantOrderItemJson(
          id: 'item-2',
          productName: 'Es Lemon Tea',
          subtotal: 5000,
        ),
      ],
    ),
  ]);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => TenantRejectOrderScreen(
          orderId: orderId,
          seedFirstItemRejected: seedFirstItemRejected,
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

  testWidgets('renders the real order and its items off the board',
      (tester) async {
    await _pump(tester);

    expect(find.text('Tolak Pesanan'), findsOneWidget);
    expect(find.text('#$_orderId'), findsOneWidget);
    expect(find.text('RCP-92842'), findsOneWidget);
    expect(find.text('10 Mei 2024 10:36 WIB'), findsOneWidget);
    expect(find.text('Anda dapat menolak sebagian item'), findsOneWidget);
    expect(find.text('Daftar Item'), findsOneWidget);
    expect(find.text('Paket Super Besar'), findsOneWidget);
    expect(find.text('Es Lemon Tea'), findsOneWidget);
    // Both items available → both show the Tersedia chip, total = 40.000.
    expect(find.text('Tersedia'), findsNWidgets(2));
    expect(find.text('2 item tersedia'), findsOneWidget);
    expect(find.text('Rp40.000'), findsOneWidget);
  });

  testWidgets('no reason capture — this API has no such field', (tester) async {
    await _pump(tester);

    expect(find.text('Alasan Penolakan'), findsNothing);
    expect(find.text('Stok Habis'), findsNothing);
  });

  testWidgets('confirm is disabled until at least one item is rejected',
      (tester) async {
    await _pump(tester);

    expect(_confirmButton(tester).onPressed, isNull);

    await tester.tap(find.byType(AppToggle).at(1));
    await tester.pumpAndSettle();

    expect(_confirmButton(tester).onPressed, isNotNull);
  });

  testWidgets(
    'toggling an item off (no reason sheet) updates the row + summary',
    (tester) async {
      await _pump(tester);

      await tester.tap(find.byType(AppToggle).at(1));
      await tester.pumpAndSettle();

      expect(find.text('Tidak Tersedia'), findsOneWidget);
      expect(find.text('1 item ditolak oleh tenant'), findsOneWidget);
      expect(find.text('1 dari 2 item tersedia'), findsOneWidget);
      // Accepted total drops to Paket Super Besar only.
      expect(find.text('Rp35.000'), findsWidgets);
      // No reason prompt anywhere in the toggle flow.
      expect(find.text('Alasan Menolak Item'), findsNothing);
    },
  );

  testWidgets('konfirmasi-pesanan deep link seeds the first item rejected',
      (tester) async {
    await _pump(tester, seedFirstItemRejected: true);

    expect(find.text('Tidak Tersedia'), findsOneWidget);
    expect(find.text('1 item ditolak oleh tenant'), findsOneWidget);
    expect(_confirmButton(tester).onPressed, isNotNull);
  });

  group('confirm flow', () {
    testWidgets(
      'confirming a partial rejection calls process with only the rejected '
      'ids and moves the order to Diproses',
      (tester) async {
        final adapter = await _pump(tester, seedFirstItemRejected: true);

        await tester.tap(find.text('Konfirmasi Pesanan'));
        await tester.pumpAndSettle();

        expect(adapter.lastRequest?.method, 'POST');
        expect(adapter.lastRequest?.path, '/v1/orders/$_orderId/process');
        expect(adapter.lastRequest?.data, {
          'rejected_item_ids': ['item-1'],
        });

        expect(find.text('Pesanan dikonfirmasi'), findsOneWidget);
        expect(find.text('1 item diterima'), findsOneWidget);
        expect(find.text('1 item ditolak'), findsOneWidget);

        await tester.tap(find.text('Konfirmasi Pesanan').last);
        await tester.pumpAndSettle();
        expect(find.byType(TenantOrderScreen), findsOneWidget);
      },
    );

    testWidgets(
      'rejecting every item sends every item id',
      (tester) async {
        final adapter = await _pump(tester);

        await tester.tap(find.byType(AppToggle).at(0));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(AppToggle).at(1));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Konfirmasi Pesanan'));
        await tester.pumpAndSettle();

        expect(adapter.lastRequest?.data, {
          'rejected_item_ids': ['item-1', 'item-2'],
        });
        expect(find.text('0 item diterima'), findsOneWidget);
        expect(find.text('2 item ditolak'), findsOneWidget);
      },
    );

    // The regression test for the silent-failure bug: rejecting an order that
    // IS on the board has to actually reach the backend.
    testWidgets('an order id not on the board surfaces not-found, no confirm',
        (tester) async {
      final adapter = await _pump(tester, orderId: 'ghost-order');

      expect(find.text(orderNotFoundMessage), findsOneWidget);
      // No confirm affordance at all, so no way to fake a success.
      expect(find.text('Konfirmasi Pesanan'), findsNothing);
      expect(find.text('Pesanan dikonfirmasi'), findsNothing);
      // Only the board's own GET happened — nothing was POSTed.
      expect(adapter.lastRequest?.method, 'GET');
    });
  });
}

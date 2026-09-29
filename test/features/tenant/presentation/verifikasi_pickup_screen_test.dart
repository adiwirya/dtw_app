import 'dart:async';

import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_order_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/verifikasi_pickup_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/pickup_code_numpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/canned_dio.dart';
import '../../../support/fake_tenant_realtime_service.dart';
import '../../../support/routed_dio.dart';
import '../../../support/tenant_board.dart';

const _orderId = 'order-1';

/// Broadcast-shaped payload for a READY self-pickup order — the only path
/// today that can carry `is_delivery` (see the Spec's Blocking Questions).
Map<String, dynamic> _selfPickupReadyPayload({
  int grandTotal = 40000,
  List<Map<String, dynamic>> items = const [],
}) => {
  'order_group': {'is_delivery': false, 'table_number': 'A-12'},
  'order': tenantOrderJson(
    id: _orderId,
    status: 'READY',
    grandTotal: grandTotal,
    receiptNumber: 'RCP-92842',
    items: items,
  ),
};

PrimaryButton _cekKodeButton(WidgetTester tester) =>
    tester.widget<PrimaryButton>(find.byType(PrimaryButton));

Finder _numpadKey(String digit) => find.descendant(
      of: find.byType(PickupCodeNumpad),
      matching: find.text(digit),
    );

Future<void> _tapCode(WidgetTester tester, String digits) async {
  for (final digit in digits.split('')) {
    await tester.tap(_numpadKey(digit));
    await tester.pump();
  }
}

Future<
    ({
      CannedAdapter adapter,
      FakeTenantRealtimeService realtime,
    })> _pump(
  WidgetTester tester, {
  String orderId = _orderId,
  Map<String, dynamic>? seedPayload,
}) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final dio = cannedOrderListDio(const []);
  final realtime = FakeTenantRealtimeService();
  addTearDown(realtime.close);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => VerifikasiPickupScreen(orderId: orderId),
      ),
      GoRoute(
        path: '/diproses',
        name: TenantRoutes.pesananDiproses,
        builder: (context, state) => const TenantOrderScreen(
          initialStatus: IncomingOrderStatus.diproses,
        ),
      ),
      GoRoute(
        path: '/order',
        name: TenantRoutes.order,
        builder: (context, state) => const TenantOrderScreen(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: tenantBoardOverrides(dio: dio, realtime: realtime),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  realtime.emitOrderCreated(seedPayload ?? _selfPickupReadyPayload());
  await tester.pumpAndSettle();

  return (adapter: dio.httpClientAdapter as CannedAdapter, realtime: realtime);
}

void main() {
  testWidgets('renders the title, subtitle and disabled Cek Kode initially',
      (tester) async {
    await _pump(tester);

    expect(find.text('Verifikasi Pickup'), findsOneWidget);
    expect(
      find.text('Masukkan kode pickup yang diberikan oleh customer'),
      findsOneWidget,
    );
    expect(_cekKodeButton(tester).onPressed, isNull);
  });

  testWidgets('digit entry via the numpad fills the boxes; backspace removes',
      (tester) async {
    await _pump(tester);

    await _tapCode(tester, '123');
    await tester.pump();
    expect(find.text('1'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('3'), findsWidgets);

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    // Still disabled — only 2 digits now.
    expect(_cekKodeButton(tester).onPressed, isNull);
  });

  testWidgets('Cek Kode enables only once 6 digits are entered',
      (tester) async {
    await _pump(tester);

    await _tapCode(tester, '12345');
    expect(_cekKodeButton(tester).onPressed, isNull);

    await _tapCode(tester, '6');
    expect(_cekKodeButton(tester).onPressed, isNotNull);
  });

  testWidgets(
      'a correct code POSTs to complete-pickup and shows the success view',
      (tester) async {
    final result = await _pump(
      tester,
      seedPayload: _selfPickupReadyPayload(
        items: [
          tenantOrderItemJson(
            id: 'item-1',
            productName: 'Paket Super Besar',
            subtotal: 35000,
          ),
        ],
      ),
    );

    await _tapCode(tester, '123456');
    await tester.tap(find.text('Cek Kode'));
    await tester.pumpAndSettle();

    expect(result.adapter.lastRequest?.path, '/v1/orders/$_orderId/complete-pickup');
    expect(result.adapter.lastRequest?.data, {'pickup_code': '123456'});
    expect(find.text('Order Ditemukan!'), findsOneWidget);
    expect(find.text('Pesanan berhasil diserahkan!'), findsOneWidget);
    expect(find.text('Paket Super Besar'), findsOneWidget);
    expect(find.text('Pesanan Selesai'), findsOneWidget);
  });

  testWidgets(
      'a wrong code (422) clears the boxes and shows an inline error, no '
      'SnackBar', (tester) async {
    // Routed, not a single-response cannedDio: the board's own initial GET
    // must succeed so the seeded order is actually on the board when
    // complete-pickup is called — only that one call needs to 422.
    final dio = routedDio({
      'POST /v1/orders/$_orderId/complete-pickup': (
        422,
        {
          'meta': {
            'success': false,
            'message': 'Validation failed.',
            'code': 422,
            'trace_id': 'abc',
          },
          'errors': {
            'pickup_code': ['Kode pickup tidak sesuai.'],
          },
        },
      ),
      '/v1/orders': (200, tenantEnvelope(const [])),
    });
    final realtime = FakeTenantRealtimeService();
    addTearDown(realtime.close);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const VerifikasiPickupScreen(orderId: _orderId),
        ),
      ],
    );
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: tenantBoardOverrides(dio: dio, realtime: realtime),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    realtime.emitOrderCreated(_selfPickupReadyPayload());
    await tester.pumpAndSettle();

    await _tapCode(tester, '000000');
    await tester.tap(find.text('Cek Kode'));
    await tester.pumpAndSettle();

    expect(find.text('Kode pickup tidak sesuai.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    // Boxes cleared: no lingering digit text, Cek Kode disabled again.
    expect(_cekKodeButton(tester).onPressed, isNull);
  });

  testWidgets('back button pops the route', (tester) async {
    final router = GoRouter(
      initialLocation: '/order',
      routes: [
        GoRoute(
          path: '/order',
          name: TenantRoutes.order,
          builder: (context, state) => const TenantOrderScreen(),
        ),
        GoRoute(
          path: '/verifikasi',
          builder: (context, state) =>
              const VerifikasiPickupScreen(orderId: _orderId),
        ),
      ],
    );
    final dio = cannedOrderListDio(const []);
    final realtime = FakeTenantRealtimeService();
    addTearDown(realtime.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: tenantBoardOverrides(dio: dio, realtime: realtime),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(router.push('/verifikasi'));
    await tester.pumpAndSettle();
    expect(find.text('Verifikasi Pickup'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('Verifikasi Pickup'), findsNothing);
  });
}

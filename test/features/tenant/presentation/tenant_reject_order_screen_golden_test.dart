import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_order_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_reject_order_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/tenant_board.dart';

const _orderId = 'order-1';

/// Self-goldens for the tenant reject screen in its two states
/// (`pesanan-ditolak`, nothing rejected yet / `konfirmasi-pesanan`, the first
/// item rejected).
///
/// NOTE: like the other tenant goldens, the harness loads Material + obra icons
/// but not Open Sans, so these show the default family and cannot be
/// pixel-diffed against the references — they pin layout against regressions.
/// Fidelity vs. the references was confirmed separately (see the work-item
/// report).
Future<void> _pump(
  WidgetTester tester, {
  bool seedFirstItemRejected = false,
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
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => TenantRejectOrderScreen(
          orderId: _orderId,
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
}

void main() {
  testWidgets(
    'reject screen — pesanan-ditolak (nothing rejected yet)',
    (tester) async {
      await _pump(tester);
      await expectLater(
        find.byType(TenantRejectOrderScreen),
        matchesGoldenFile('goldens/tenant_pesanan_ditolak.png'),
      );
    },
    tags: 'golden',
  );

  testWidgets(
    'reject screen — konfirmasi-pesanan (first item rejected)',
    (tester) async {
      await _pump(tester, seedFirstItemRejected: true);
      await expectLater(
        find.byType(TenantRejectOrderScreen),
        matchesGoldenFile('goldens/tenant_konfirmasi_pesanan.png'),
      );
    },
    tags: 'golden',
  );
}

import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_order_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/tenant_board.dart';

/// Self-golden for the `menu-order-baru-2` "Detail Pesanan" screen (from a
/// card tap) on a Baru order — nav bar, order card, summary and the
/// Tolak/Terima bar. See the reject-screen golden note about fonts.
void main() {
  testWidgets(
    'menu-order-baru-2 order detail (Baru board)',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const TenantOrderDetailScreen(orderId: 'order-1'),
          ),
          GoRoute(
            path: '/ditolak',
            name: TenantRoutes.pesananDitolak,
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/baru-2',
            name: TenantRoutes.orderDetail,
            builder: (context, state) => const SizedBox.shrink(),
          ),
        ],
      );

      // The screen watches the real `tenantOrderBoardProvider`. Without these
      // overrides the board's initial fetch hangs on the unmocked
      // `flutter_secure_storage` channel, the spinner never stops, and
      // `pumpAndSettle` times out.
      await tester.pumpWidget(
        ProviderScope(
          overrides: tenantBoardOverrides(
            dio: cannedOrderListDio([
              tenantOrderJson(
                id: 'order-1',
                status: 'PENDING',
                tableNumber: 'A-12',
                customerName: 'Budi Santoso',
                isDelivery: true,
                grandTotal: 40000,
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
            ]),
          ),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TenantOrderDetailScreen),
        matchesGoldenFile('goldens/tenant_order_baru_2.png'),
      );
    },
    tags: 'golden',
  );
}

import 'package:dtw_app/features/order/presentation/screens/order_selesai_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/busboy_board.dart';

/// Self-golden for the `detail-selesai` completed-order detail screen.
///
/// NOTE: the headless harness does not load Open Sans (the cache font), so the
/// golden intentionally shows placeholder text metrics and CANNOT be pixel-
/// diffed against the Figma `reference.png`. The Obra icon font IS loaded (see
/// `flutter_test_config.dart`). This golden pins layout (structure, spacing,
/// colours, card placement) against regressions; fidelity vs. the
/// `detail-selesai` reference was confirmed separately by rendering and
/// comparing screenshots (see the work-item report).
void main() {
  testWidgets(
    'detail-selesai self-golden',
    (tester) async {
      // The design frame is 390x950; the body is scrollable so lay it out at
      // the frame height.
      tester.view.physicalSize = const Size(390, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final dio = cannedDeliveryListDio([
        deliveryJson(
          id: '1',
          status: 'DELIVERED',
          tableNumber: 'A-12',
          claimedAt: '2026-08-27 10:27:00',
          deliveredAt: '2026-08-27 10:45:00',
          orders: [
            deliveryOrderJson(
              orderId: 'order-1',
              items: [
                deliveryItemJson(productName: 'Paket Super Besar'),
                deliveryItemJson(productName: 'Es Lemon Tea'),
              ],
            ),
          ],
        ),
      ]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: busboyBoardOverrides(dio: dio),
          child: const MaterialApp(
            home: OrderSelesaiDetailScreen(orderId: '1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(OrderSelesaiDetailScreen),
        matchesGoldenFile('goldens/detail_selesai.png'),
      );
    },
    tags: 'golden',
  );
}

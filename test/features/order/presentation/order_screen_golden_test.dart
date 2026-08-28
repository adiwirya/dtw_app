import 'package:dtw_app/features/order/presentation/screens/order_detail_screen.dart';
import 'package:dtw_app/features/order/presentation/screens/order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/busboy_board.dart';

/// Self-goldens for the Menu Order screens.
///
/// NOTE: the headless harness does not load Open Sans (the cache font), so the
/// goldens intentionally show placeholder text metrics and CANNOT be pixel-
/// diffed against the Figma `reference.png`. The Obra icon font IS loaded (see
/// `flutter_test_config.dart`). These goldens pin layout (structure, spacing,
/// colours, card placement) against regressions; fidelity vs. the four
/// references was confirmed separately by rendering and comparing screenshots
/// (see the work-item report).
void main() {
  List<Map<String, dynamic>> seedDeliveries() => [
    deliveryJson(
      id: '1',
      status: 'PENDING_PICKUP',
      orders: [deliveryOrderJson(orderId: 'order-1')],
    ),
    deliveryJson(
      id: '2',
      status: 'CLAIMED',
      orders: [deliveryOrderJson(orderId: 'order-2')],
    ),
    deliveryJson(
      id: '3',
      status: 'DELIVERED',
      deliveredAt: '2026-08-27 10:45:00',
      orders: [deliveryOrderJson(orderId: 'order-3')],
    ),
  ];

  Future<void> pumpOrder(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: busboyBoardOverrides(
          dio: cannedDeliveryListDio(seedDeliveries()),
        ),
        child: const MaterialApp(home: OrderScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'menu-order-baru self-golden',
    (tester) async {
      await pumpOrder(tester);
      await expectLater(
        find.byType(OrderScreen),
        matchesGoldenFile('goldens/menu_order_baru.png'),
      );
    },
    tags: 'golden',
  );

  testWidgets(
    'menu-order-antar self-golden',
    (tester) async {
      await pumpOrder(tester);
      await tester.tap(find.text('Antar'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(OrderScreen),
        matchesGoldenFile('goldens/menu_order_antar.png'),
      );
    },
    tags: 'golden',
  );

  testWidgets(
    'menu-order-selesai self-golden',
    (tester) async {
      await pumpOrder(tester);
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(OrderScreen),
        matchesGoldenFile('goldens/menu_order_selesai.png'),
      );
    },
    tags: 'golden',
  );

  testWidgets(
    'menu-order-baru-2 (detail) self-golden',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: busboyBoardOverrides(
            dio: cannedDeliveryListDio([
              deliveryJson(
                id: '1',
                status: 'PENDING_PICKUP',
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
            ]),
          ),
          child: const MaterialApp(home: OrderDetailScreen(orderId: '1')),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(OrderDetailScreen),
        matchesGoldenFile('goldens/menu_order_baru_2.png'),
      );
    },
    tags: 'golden',
  );
}

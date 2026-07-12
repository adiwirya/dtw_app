import 'package:dtw_app/features/order/presentation/screens/order_detail_screen.dart';
import 'package:dtw_app/features/order/presentation/screens/order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  Future<void> pumpOrder(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OrderScreen()),
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
        const ProviderScope(
          child: MaterialApp(home: OrderDetailScreen()),
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

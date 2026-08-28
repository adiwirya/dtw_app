import 'package:dtw_app/features/riwayat/presentation/screens/riwayat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/busboy_board.dart';

/// `Delivery.fromJson` parses `created_at`/`delivered_at` as
/// `yyyy-MM-dd HH:mm:ss` (naive local) — this is that same wire format, so
/// fixtures can be built relative to the real "now" the screen buckets
/// against (`RiwayatScreen` calls `DateTime.now()` itself, not a fake clock).
String _wire(DateTime at) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${at.year}-${two(at.month)}-${two(at.day)} '
      '${two(at.hour)}:${two(at.minute)}:${two(at.second)}';
}

/// Self-goldens for the Riwayat screens.
///
/// NOTE: the headless harness does not load Open Sans (the cache font), so the
/// goldens intentionally show placeholder text metrics and CANNOT be pixel-
/// diffed against the Figma `reference.png`. The Obra icon font IS loaded (see
/// `flutter_test_config.dart`). These goldens pin layout (structure, spacing,
/// colours, card placement) against regressions; fidelity vs. the three
/// references was confirmed separately by rendering and comparing screenshots
/// (see the work-item report).
void main() {
  final now = DateTime.now();
  final today = _wire(now);
  final yesterday = _wire(now.subtract(const Duration(days: 1)));

  List<Map<String, dynamic>> seedDeliveries() => [
    deliveryJson(
      id: '1',
      status: 'DELIVERED',
      deliveredAt: today,
      orders: [deliveryOrderJson(orderId: 'order-1')],
    ),
    deliveryJson(
      id: '2',
      status: 'DELIVERED',
      deliveredAt: today,
      orders: [deliveryOrderJson(orderId: 'order-2', brandName: 'Solaria')],
    ),
    deliveryJson(
      id: '3',
      status: 'DELIVERED',
      deliveredAt: yesterday,
      orders: [
        deliveryOrderJson(orderId: 'order-3', brandName: 'J.CO Donuts'),
      ],
    ),
  ];

  Future<void> pumpRiwayat(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: busboyBoardOverrides(
          dio: cannedDeliveryListDio(seedDeliveries()),
        ),
        child: const MaterialApp(home: RiwayatScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'riwayat-hari-ini self-golden',
    (tester) async {
      await pumpRiwayat(tester);
      await expectLater(
        find.byType(RiwayatScreen),
        matchesGoldenFile('goldens/riwayat_hari_ini.png'),
      );
    },
    tags: 'golden',
  );

  testWidgets(
    'riwayat-kemarin self-golden',
    (tester) async {
      await pumpRiwayat(tester);
      await tester.tap(find.text('Kemarin'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(RiwayatScreen),
        matchesGoldenFile('goldens/riwayat_kemarin.png'),
      );
    },
    tags: 'golden',
  );

  testWidgets(
    'riwayat-7-hari self-golden',
    (tester) async {
      await pumpRiwayat(tester);
      await tester.tap(find.text('7 Hari Terakhir'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(RiwayatScreen),
        matchesGoldenFile('goldens/riwayat_7_hari.png'),
      );
    },
    tags: 'golden',
  );
}

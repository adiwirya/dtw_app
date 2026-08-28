import 'package:dtw_app/core/widgets/segmented_tab_bar.dart';
import 'package:dtw_app/features/order/data/models/delivery.dart';
import 'package:dtw_app/features/riwayat/data/models/riwayat_models.dart';
import 'package:dtw_app/features/riwayat/presentation/screens/riwayat_screen.dart';
import 'package:dtw_app/features/riwayat/presentation/widgets/history_row.dart';
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

Widget _wrap(List<Map<String, dynamic>> deliveries) {
  return ProviderScope(
    overrides: busboyBoardOverrides(dio: cannedDeliveryListDio(deliveries)),
    child: const MaterialApp(home: RiwayatScreen()),
  );
}

void main() {
  final now = DateTime.now();
  final today = _wire(now);
  final yesterday = _wire(now.subtract(const Duration(days: 1)));
  final eightDaysAgo = _wire(now.subtract(const Duration(days: 8)));
  final todayLabel = Delivery.formatDate(
    DateTime(now.year, now.month, now.day),
  );
  final yesterdayLabel = Delivery.formatDate(
    DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1)),
  );

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
      deliveredAt: today,
      orders: [
        deliveryOrderJson(orderId: 'order-3', brandName: 'J.CO Donuts'),
      ],
    ),
    deliveryJson(
      id: '4',
      status: 'DELIVERED',
      deliveredAt: yesterday,
      orders: [deliveryOrderJson(orderId: 'order-4', brandName: 'Solaria')],
    ),
    deliveryJson(
      id: '5',
      status: 'DELIVERED',
      deliveredAt: yesterday,
      orders: [
        deliveryOrderJson(orderId: 'order-5', brandName: 'Starbucks'),
      ],
    ),
    // Outside the 7-day window — must never show up on any tab.
    deliveryJson(
      id: '6',
      status: 'DELIVERED',
      deliveredAt: eightDaysAgo,
      orders: [deliveryOrderJson(orderId: 'order-6', brandName: 'Excluded')],
    ),
  ];

  testWidgets('renders the three date tabs from the segmented bar',
      (tester) async {
    await tester.pumpWidget(_wrap(seedDeliveries()));
    await tester.pumpAndSettle();

    expect(find.byType(SegmentedTabBar), findsOneWidget);
    expect(find.text('Hari Ini'), findsOneWidget);
    expect(find.text('Kemarin'), findsOneWidget);
    expect(find.text('7 Hari Terakhir'), findsOneWidget);
  });

  testWidgets('Hari Ini tab shows today history + date header', (tester) async {
    await tester.pumpWidget(_wrap(seedDeliveries()));
    await tester.pumpAndSettle();

    expect(find.text(todayLabel), findsOneWidget);
    expect(find.text('3 Tugas'), findsOneWidget);
    expect(find.byType(HistoryRow), findsNWidgets(3));
    expect(find.text('Janji Jiwa'), findsOneWidget);
    expect(find.text('J.CO Donuts'), findsOneWidget);
    expect(find.text('Excluded'), findsNothing);
  });

  testWidgets('switching to Kemarin swaps the list in place', (tester) async {
    await tester.pumpWidget(_wrap(seedDeliveries()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kemarin'));
    await tester.pumpAndSettle();

    expect(find.text(yesterdayLabel), findsOneWidget);
    expect(find.text('2 Tugas'), findsOneWidget);
    expect(find.byType(HistoryRow), findsNWidgets(2));
    expect(find.text('Solaria'), findsOneWidget);
    expect(find.text('Janji Jiwa'), findsNothing);
  });

  testWidgets('7 Hari Terakhir stacks multiple date groups, excludes older',
      (tester) async {
    // Tall surface so the whole (lazy) list is laid out at once.
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(seedDeliveries()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('7 Hari Terakhir'));
    await tester.pumpAndSettle();

    // Both recent day groups render (5 rows total); the 8-day-old delivery
    // is excluded.
    expect(find.text(todayLabel), findsOneWidget);
    expect(find.text(yesterdayLabel), findsOneWidget);
    expect(find.byType(HistoryRow), findsNWidgets(5));
    expect(find.text('Excluded'), findsNothing);
  });

  testWidgets('an empty range shows the empty state', (tester) async {
    await tester.pumpWidget(_wrap(const []));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada riwayat pesanan.'), findsOneWidget);
    expect(find.byType(HistoryRow), findsNothing);
  });

  testWidgets('tapping a row invokes navigation to detail', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HistoryRow(
              entry: const RiwayatEntry(
                id: 'delivery-1',
                time: '10:45',
                statusLabel: 'Selesai',
                tenantName: 'Janji Jiwa',
                tableName: 'Meja A-12',
                location: '',
              ),
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Detail'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });
}

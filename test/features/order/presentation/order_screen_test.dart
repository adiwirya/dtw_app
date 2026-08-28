import 'package:dtw_app/core/widgets/order_card.dart';
import 'package:dtw_app/core/widgets/segmented_tab_bar.dart';
import 'package:dtw_app/core/widgets/success_modal.dart';
import 'package:dtw_app/features/order/presentation/screens/order_screen.dart';
import 'package:dtw_app/features/order/presentation/widgets/order_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/busboy_board.dart';

/// The deliveries backing most tests: 2 pending pickup, 2 claimed, 1 already
/// delivered — matches the old mock's Baru/Antar/Selesai split so the
/// existing sub-tab assertions stay meaningful.
List<Map<String, dynamic>> _seedDeliveries() => [
  deliveryJson(
    id: '1',
    status: 'PENDING_PICKUP',
    orders: [deliveryOrderJson(orderId: 'order-1')],
  ),
  deliveryJson(
    id: '2',
    status: 'PENDING_PICKUP',
    orders: [deliveryOrderJson(orderId: 'order-2', brandName: 'Solaria')],
  ),
  deliveryJson(
    id: '3',
    status: 'CLAIMED',
    orders: [deliveryOrderJson(orderId: 'order-3')],
  ),
  deliveryJson(
    id: '4',
    status: 'CLAIMED',
    orders: [deliveryOrderJson(orderId: 'order-4', brandName: 'Solaria')],
  ),
  deliveryJson(
    id: '5',
    status: 'DELIVERED',
    deliveredAt: '2026-08-27 10:45:00',
    orders: [deliveryOrderJson(orderId: 'order-5')],
  ),
];

Widget _wrap({List<Map<String, dynamic>>? deliveries}) {
  return ProviderScope(
    overrides: busboyBoardOverrides(
      dio: cannedDeliveryListDio(deliveries ?? _seedDeliveries()),
    ),
    child: const MaterialApp(home: OrderScreen()),
  );
}

void main() {
  testWidgets('renders the three sub-tabs from the segmented bar',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.byType(SegmentedTabBar), findsOneWidget);
    expect(find.text('Ambil'), findsOneWidget);
    expect(find.text('Antar'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
  });

  testWidgets('Baru sub-tab shows the populated order list', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.byType(OrderCard), findsNWidgets(2));
    expect(find.text('Janji Jiwa'), findsOneWidget);
    expect(find.text('Solaria'), findsOneWidget);
    // Baru cards expose the Detail affordance, no action button.
    expect(find.text('Detail'), findsNWidgets(2));
    expect(find.text('Sampai dimeja'), findsNothing);
  });

  testWidgets('switching to Antar shows the deliver action button',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Antar'));
    await tester.pumpAndSettle();

    expect(find.text('Sampai dimeja'), findsNWidgets(2));
  });

  testWidgets('an empty sub-tab renders the empty state', (tester) async {
    await tester.pumpWidget(
      _wrap(
        deliveries: [
          deliveryJson(id: '1', status: 'PENDING_PICKUP'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Antar'));
    await tester.pumpAndSettle();

    expect(find.byType(OrderEmptyState), findsOneWidget);
    expect(find.byType(OrderCard), findsNothing);
  });

  testWidgets(
      'delivering an Antar order raises the success modal and moves it to '
      'Selesai on confirm', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Antar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sampai dimeja').first);
    await tester.pumpAndSettle();

    // The shared success modal (berhasil-ditambahkan-2 copy) is shown.
    expect(find.byType(SuccessModal), findsOneWidget);
    expect(find.text('Sampai dimeja'), findsWidgets); // modal title
    expect(find.text('Lanjutkan'), findsOneWidget);

    // Confirm: modal pops and the Selesai sub-tab is now selected.
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    expect(find.byType(SuccessModal), findsNothing);
    // Selesai now has the original delivered order + the just-delivered one.
    expect(find.byType(OrderCard), findsNWidgets(2));
    expect(find.text('Diantar pada'), findsNWidgets(2));
  });
}

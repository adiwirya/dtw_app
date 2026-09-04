import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/widgets/success_modal.dart';
import 'package:dtw_app/features/order/presentation/screens/order_detail_screen.dart';
import 'package:dtw_app/features/order/presentation/screens/order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/busboy_board.dart';
import '../../../support/canned_dio.dart';

const _deliveryId = '1';
const _receiptNumber = 'RCP-20260827-B07XYZ';

/// Finds [text] only inside the success modal, so an assertion can't be
/// satisfied by the detail screen still sitting behind the dialog.
Finder _inModal(String text) => find.descendant(
      of: find.byType(SuccessModal),
      matching: find.text(text),
    );

/// Pumps the detail screen for a single delivery whose fields are
/// deliberately nothing like `SuccessModal`'s hardcoded frame sample.
/// [status] defaults to PENDING_PICKUP; pass 'CLAIMED' to exercise an
/// already-taken delivery.
Future<CannedAdapter> _pump(
  WidgetTester tester, {
  String status = 'PENDING_PICKUP',
}) async {
  tester.view.physicalSize = const Size(390, 950);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final dio = cannedDeliveryListDio([
    deliveryJson(
      id: _deliveryId,
      status: status,
      tableNumber: 'B-07',
      customerName: 'Siti Aminah',
      orders: [
        deliveryOrderJson(
          orderId: 'order-1',
          brandName: 'Solaria',
          receiptNumber: _receiptNumber,
          items: [deliveryItemJson(productName: 'Nasi Goreng', quantity: 2)],
        ),
      ],
    ),
  ]);

  await tester.pumpWidget(
    ProviderScope(
      overrides: busboyBoardOverrides(dio: dio),
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/order/detail/$_deliveryId',
          routes: [
            GoRoute(
              path: '/order',
              name: AppRoutes.order,
              builder: (_, _) => const OrderScreen(),
              routes: [
                GoRoute(
                  path: 'detail/:orderId',
                  name: AppRoutes.orderDetail,
                  builder: (context, state) => OrderDetailScreen(
                    orderId: state.pathParameters['orderId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return dio.httpClientAdapter as CannedAdapter;
}

void main() {
  testWidgets('renders the claimed delivery off the real board',
      (tester) async {
    await _pump(tester);

    expect(find.text('Detail Pesanan'), findsOneWidget);
    expect(find.text('#$_receiptNumber'), findsOneWidget);
    expect(find.text('Solaria'), findsOneWidget);
    expect(find.text('Siti Aminah'), findsOneWidget);
    expect(find.text('Ambil Pesanan'), findsOneWidget);
  });

  testWidgets(
      'hides Ambil Pesanan once the delivery is already claimed',
      (tester) async {
    await _pump(tester, status: 'CLAIMED');

    expect(find.text('Ambil Pesanan'), findsNothing);
  });

  testWidgets('Ambil Pesanan claims the real delivery', (tester) async {
    final adapter = await _pump(tester);

    await tester.tap(find.text('Ambil Pesanan'));
    await tester.pumpAndSettle();

    expect(adapter.lastRequest?.method, 'POST');
    expect(
      adapter.lastRequest?.path,
      '/v1/busboy/deliveries/$_deliveryId/claim',
    );
  });

  // Regression test: the CTA used to raise `showSuccessModal` with no
  // `details:`, which silently fell back to SuccessModal's hardcoded
  // `berhasil-ditambahkan` frame sample. A busboy who claimed a real delivery
  // was shown a confirmation for "KFC Fried Chicken / Meja A-12 / Budi
  // Santoso" — an order that was not the one just taken.
  testWidgets(
      'the success modal shows the claimed delivery, not the frame sample',
      (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Ambil Pesanan'));
    await tester.pumpAndSettle();

    expect(find.byType(SuccessModal), findsOneWidget);
    // The frame's own copy is still the right copy for this action.
    expect(find.text('Tugas Berhasil Diambil!'), findsOneWidget);

    // The detail rows are the claimed delivery's.
    expect(_inModal('Solaria'), findsOneWidget);
    expect(_inModal('Siti Aminah'), findsOneWidget);
    // A busboy delivery has no zone name, so no dangling dot separator.
    expect(_inModal('Meja B-07'), findsOneWidget);

    // None of the hardcoded sample leaks through anywhere on screen.
    expect(find.text('KFC Fried Chicken'), findsNothing);
    expect(find.text('Budi Santoso'), findsNothing);
    expect(find.text('Meja A-12  •  Downtown'), findsNothing);
  });

  testWidgets('confirming the modal returns to the Order home', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Ambil Pesanan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mengerti'));
    await tester.pumpAndSettle();

    expect(find.byType(SuccessModal), findsNothing);
    expect(find.byType(OrderScreen), findsOneWidget);
  });
}

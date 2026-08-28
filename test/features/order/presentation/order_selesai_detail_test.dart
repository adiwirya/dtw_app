import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/widgets/completed_detail_view.dart';
import 'package:dtw_app/core/widgets/order_card.dart';
import 'package:dtw_app/features/order/presentation/screens/order_screen.dart';
import 'package:dtw_app/features/order/presentation/screens/order_selesai_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/busboy_board.dart';
import '../../../support/canned_dio.dart';

const _deliveryId = '1';

/// Minimal router exercising the Order → Selesai → completed-order detail flow
/// so navigation targets can be asserted without the full app shell.
GoRouter _router() => GoRouter(
      initialLocation: '/order',
      routes: [
        GoRoute(
          path: '/order',
          name: AppRoutes.order,
          builder: (_, _) => const OrderScreen(),
          routes: [
            GoRoute(
              path: 'selesai',
              name: AppRoutes.orderSelesai,
              builder: (_, _) => const OrderScreen(),
              routes: [
                GoRoute(
                  path: 'detail/:orderId',
                  name: AppRoutes.orderSelesaiDetail,
                  builder: (context, state) => OrderSelesaiDetailScreen(
                    orderId: state.pathParameters['orderId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

Future<CannedAdapter> _pump(
  WidgetTester tester, {
  String orderId = _deliveryId,
}) async {
  tester.view.physicalSize = const Size(390, 950);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final dio = cannedDeliveryListDio([
    deliveryJson(
      id: _deliveryId,
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
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/detail/$orderId',
          routes: [
            GoRoute(
              path: '/detail/:orderId',
              builder: (context, state) => OrderSelesaiDetailScreen(
                orderId: state.pathParameters['orderId']!,
              ),
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
  testWidgets(
      'renders the key detail-selesai content off the real delivery',
      (tester) async {
    await _pump(tester);

    expect(find.text('Detail Pesanan'), findsOneWidget);
    expect(find.text('#$_deliveryId'), findsOneWidget);
    expect(find.text('Alur Tugas'), findsOneWidget);
    expect(find.text('Informasi Pesanan'), findsOneWidget);
    expect(find.text('Rincian item'), findsOneWidget);
    // Only the two real timestamps the API has — no fabricated "Diantar"
    // middle step.
    expect(find.text('Diambil'), findsOneWidget);
    expect(find.text('Diantar'), findsNothing);
    expect(find.text('Sampai Dimeja'), findsOneWidget);
    // 10:45 - 10:27 = 18 minutes.
    expect(find.text('18 Menit'), findsOneWidget);
    // No price data on the busboy API — shown as a placeholder.
    expect(find.text('-'), findsWidgets);
    // detail-selesai shows the tenant name both as the card title and as the
    // "Tenan" info-row value.
    expect(find.text('Janji Jiwa'), findsNWidgets(2));
  });

  testWidgets('an unknown delivery id surfaces not-found, not a crash',
      (tester) async {
    await _pump(tester, orderId: 'ghost-order');

    expect(
      find.text('Pesanan tidak ditemukan di daftar order.'),
      findsOneWidget,
    );
    expect(find.byType(CompletedDetailView), findsNothing);
  });

  testWidgets('back button pops to the previous route', (tester) async {
    final router = _router();
    await tester.pumpWidget(
      ProviderScope(
        overrides: busboyBoardOverrides(
          dio: cannedDeliveryListDio([
            deliveryJson(id: _deliveryId, status: 'DELIVERED'),
          ]),
        ),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Drive directly to the detail route, then pop via the nav-bar back button.
    router.goNamed(
      AppRoutes.orderSelesaiDetail,
      pathParameters: {'orderId': _deliveryId},
    );
    await tester.pumpAndSettle();
    expect(find.byType(OrderSelesaiDetailScreen), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.byType(OrderSelesaiDetailScreen), findsNothing);
    expect(find.byType(OrderScreen), findsOneWidget);
  });

  testWidgets(
      'tapping a Selesai card opens the completed-order detail for that '
      'delivery', (tester) async {
    tester.view.physicalSize = const Size(390, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: busboyBoardOverrides(
          dio: cannedDeliveryListDio([
            deliveryJson(id: _deliveryId, status: 'DELIVERED'),
          ]),
        ),
        child: MaterialApp.router(routerConfig: _router()),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to the Selesai sub-tab in place.
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    // Tapping the completed-order card navigates to the real detail screen.
    await tester.tap(find.byType(OrderCard).first);
    await tester.pumpAndSettle();

    expect(find.byType(OrderSelesaiDetailScreen), findsOneWidget);
    expect(find.byType(CompletedDetailView), findsOneWidget);
    expect(find.text('#$_deliveryId'), findsOneWidget);
  });
}

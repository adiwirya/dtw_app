import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/widgets/completed_detail_view.dart';
import 'package:dtw_app/features/riwayat/presentation/screens/riwayat_detail_screen.dart';
import 'package:dtw_app/features/riwayat/presentation/screens/riwayat_screen.dart';
import 'package:dtw_app/features/riwayat/presentation/widgets/history_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/busboy_board.dart';
import '../../../support/canned_dio.dart';

const _entryId = 'delivery-1';
const _receiptNumber = 'RCP-20260827-A12ABC';

/// Minimal router exercising the Riwayat → history-entry detail flow so
/// navigation targets can be asserted without the full app shell.
GoRouter _router() => GoRouter(
      initialLocation: '/riwayat',
      routes: [
        GoRoute(
          path: '/riwayat',
          name: AppRoutes.riwayat,
          builder: (_, _) => const RiwayatScreen(),
          routes: [
            GoRoute(
              path: 'detail/:entryId',
              name: AppRoutes.riwayatDetail,
              builder: (context, state) => RiwayatDetailScreen(
                entryId: state.pathParameters['entryId']!,
              ),
            ),
          ],
        ),
      ],
    );

Future<CannedAdapter> _pump(
  WidgetTester tester, {
  String entryId = _entryId,
}) async {
  tester.view.physicalSize = const Size(390, 950);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final dio = cannedDeliveryListDio([
    deliveryJson(
      id: _entryId,
      status: 'DELIVERED',
      tableNumber: 'A-12',
      claimedAt: '2026-08-27 10:27:00',
      deliveredAt: '2026-08-27 10:45:00',
      orders: [
        deliveryOrderJson(
          orderId: 'order-1',
          receiptNumber: _receiptNumber,
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
          initialLocation: '/detail/$entryId',
          routes: [
            GoRoute(
              path: '/detail/:entryId',
              builder: (context, state) => RiwayatDetailScreen(
                entryId: state.pathParameters['entryId']!,
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
  testWidgets('renders the key detail-riwayat content off the real delivery',
      (tester) async {
    await _pump(tester);

    expect(find.text('Detail Pesanan'), findsOneWidget);
    expect(find.text('#$_receiptNumber'), findsOneWidget);
    expect(find.text('Alur Tugas'), findsOneWidget);
    expect(find.text('Informasi Pesanan'), findsOneWidget);
    expect(find.text('Rincian item'), findsOneWidget);
    expect(find.text('Diambil'), findsOneWidget);
    expect(find.text('Sampai Dimeja'), findsOneWidget);
    // 10:45 - 10:27 = 18 minutes.
    expect(find.text('18 Menit'), findsOneWidget);
    // No zone name on the busboy API — shown as a placeholder, not
    // fabricated.
    expect(find.text('-'), findsWidgets);
    // The tenant name appears both as the card title and the "Tenan" row.
    expect(find.text('Janji Jiwa'), findsNWidgets(2));
  });

  testWidgets('an unknown entry id surfaces not-found, not a crash',
      (tester) async {
    await _pump(tester, entryId: 'ghost-entry');

    expect(find.text('Riwayat tidak ditemukan.'), findsOneWidget);
    expect(find.byType(CompletedDetailView), findsNothing);
  });

  testWidgets('back button pops to the previous route', (tester) async {
    final dio = cannedDeliveryListDio([
      deliveryJson(id: _entryId, status: 'DELIVERED'),
    ]);
    final router = _router();
    await tester.pumpWidget(
      ProviderScope(
        overrides: busboyBoardOverrides(dio: dio),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    router.goNamed(
      AppRoutes.riwayatDetail,
      pathParameters: {'entryId': _entryId},
    );
    await tester.pumpAndSettle();
    expect(find.byType(RiwayatDetailScreen), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.byType(RiwayatDetailScreen), findsNothing);
    expect(find.byType(RiwayatScreen), findsOneWidget);
  });

  testWidgets('a Riwayat row lands on the real detail screen for that '
      'delivery, not a placeholder', (tester) async {
    tester.view.physicalSize = const Size(390, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    final dio = cannedDeliveryListDio([
      deliveryJson(
        id: _entryId,
        status: 'DELIVERED',
        // Riwayat defaults to the "Hari Ini" tab, which buckets against the
        // real DateTime.now() — a fixed past date would fall off it.
        deliveredAt: '${now.year}-${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')} 10:45:00',
        orders: [
          deliveryOrderJson(orderId: 'order-1', receiptNumber: _receiptNumber),
        ],
      ),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: busboyBoardOverrides(dio: dio),
        child: MaterialApp.router(routerConfig: _router()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(HistoryRow).first);
    await tester.pumpAndSettle();

    expect(find.byType(RiwayatDetailScreen), findsOneWidget);
    expect(find.byType(CompletedDetailView), findsOneWidget);
    expect(find.text('#$_receiptNumber'), findsOneWidget);
  });
}

import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/features/order/presentation/screens/order_confirmation_detail_screen.dart';
import 'package:dtw_app/features/order/presentation/screens/order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/busboy_board.dart';
import '../../../support/canned_dio.dart';
import '../../../support/routed_dio.dart';
import '../order_confirmation_test.dart' show confirmationJson;

/// Pumps the Order tab (with a `konfirmasi/:id` child route) over a board with
/// one delivery and [confirmations], starting at [location].
Future<RoutedAdapter> _pump(
  WidgetTester tester, {
  required List<Map<String, dynamic>> confirmations,
  String location = '/order',
  Map<String, (int, Object?)> extra = const {},
}) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final confirmationDio = routedDio({
    'GET /v1/busboy/order-confirmations': (
      200,
      busboyEnvelope(confirmations),
    ),
    ...extra,
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: busboyBoardOverrides(
        dio: cannedDeliveryListDio([
          deliveryJson(
            id: 'd1',
            status: 'PENDING_PICKUP',
            orders: [
              deliveryOrderJson(
                orderId: 'o9',
                brandName: 'Solaria',
                items: [deliveryItemJson(productName: 'Mie')],
              ),
            ],
          ),
        ]),
        sessionUserId: 'me',
        confirmationDio: confirmationDio,
      ),
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: location,
          routes: [
            GoRoute(
              path: '/order',
              name: AppRoutes.order,
              builder: (_, _) => const OrderScreen(),
              routes: [
                GoRoute(
                  path: 'konfirmasi/:confirmationId',
                  name: AppRoutes.orderConfirmationDetail,
                  builder: (context, state) => OrderConfirmationDetailScreen(
                    confirmationId: state.pathParameters['confirmationId']!,
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
  return confirmationDio.httpClientAdapter as RoutedAdapter;
}

void main() {
  testWidgets('Ambil tab lists confirmations under a Konfirmasi section', (
    tester,
  ) async {
    await _pump(tester, confirmations: [confirmationJson()]);

    expect(find.text('Konfirmasi'), findsOneWidget);
    expect(find.text('Perlu Konfirmasi'), findsOneWidget);
    expect(find.text('1 Pesanan'), findsOneWidget);
    expect(find.text('Siap diantar'), findsOneWidget);
    // The delivery card is still there under its own heading.
    expect(find.text('Solaria'), findsOneWidget);
  });

  testWidgets('without confirmations the Ambil tab has no section headings', (
    tester,
  ) async {
    await _pump(tester, confirmations: const []);

    expect(find.text('Konfirmasi'), findsNothing);
    expect(find.text('Siap diantar'), findsNothing);
    expect(find.text('Solaria'), findsOneWidget);
  });

  testWidgets('tapping Detail opens the decision screen', (tester) async {
    await _pump(tester, confirmations: [confirmationJson()]);

    await tester.tap(find.text('Detail').first);
    await tester.pumpAndSettle();

    expect(find.text('Detail Pesanan'), findsOneWidget);
    expect(find.text('1 ITEM TIDAK TERSEDIA'), findsOneWidget);
    expect(find.text('Lanjutkan Pesanan'), findsOneWidget);
    expect(find.text('Batalkan Pesanan'), findsOneWidget);
  });

  testWidgets('a partly rejected line splits into accepted and red rows', (
    tester,
  ) async {
    await _pump(
      tester,
      confirmations: [confirmationJson()],
      location: '/order/konfirmasi/c1',
    );

    // Es Teh x2 with 1 rejected: 1 accepted + 1 rejected (with its reason).
    expect(find.text('Es Teh'), findsNWidgets(2));
    expect(find.text('Stok habis'), findsOneWidget);
    expect(find.text('Nasi'), findsOneWidget);
  });

  testWidgets('Lanjutkan claims then resolves with PROCEED', (tester) async {
    final adapter = await _pump(
      tester,
      confirmations: [confirmationJson()],
      location: '/order/konfirmasi/c1',
      extra: {
        'POST /v1/busboy/order-confirmations/c1/claim': (
          200,
          busboyEnvelope(confirmationJson(busboyUserId: 'me')),
        ),
        'POST /v1/busboy/order-confirmations/c1/resolve': (
          200,
          busboyEnvelope(
            confirmationJson(
              busboyUserId: 'me',
              resolvedAt: '2026-10-09 10:09:00',
            ),
          ),
        ),
      },
    );

    await tester.tap(find.text('Lanjutkan Pesanan'));
    await tester.pumpAndSettle();

    final posts = adapter.requests.where((r) => r.method == 'POST').toList();
    expect(posts.map((r) => r.path), [
      '/v1/busboy/order-confirmations/c1/claim',
      '/v1/busboy/order-confirmations/c1/resolve',
    ]);
    expect(posts.last.data, {'decision': 'PROCEED'});
    // Back on the Order home.
    expect(find.text('Detail Pesanan'), findsNothing);
  });

  testWidgets('Batalkan asks first; declining sends nothing', (tester) async {
    final adapter = await _pump(
      tester,
      confirmations: [confirmationJson()],
      location: '/order/konfirmasi/c1',
    );

    await tester.tap(find.text('Batalkan Pesanan'));
    await tester.pumpAndSettle();
    expect(find.text('Batalkan pesanan?'), findsOneWidget);

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();

    expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
    expect(find.text('Detail Pesanan'), findsOneWidget);
  });

  testWidgets('Batalkan confirmed resolves with CANCEL', (tester) async {
    final adapter = await _pump(
      tester,
      confirmations: [confirmationJson(busboyUserId: 'me')],
      location: '/order/konfirmasi/c1',
      extra: {
        'POST /v1/busboy/order-confirmations/c1/resolve': (
          200,
          busboyEnvelope(
            confirmationJson(
              busboyUserId: 'me',
              resolvedAt: '2026-10-09 10:09:00',
            ),
          ),
        ),
      },
    );

    await tester.tap(find.text('Batalkan Pesanan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, Batalkan'));
    await tester.pumpAndSettle();

    final posts = adapter.requests.where((r) => r.method == 'POST').toList();
    expect(posts.single.data, {'decision': 'CANCEL'});
  });

  testWidgets('a claim conflict shows the error and stays on the screen', (
    tester,
  ) async {
    await _pump(
      tester,
      confirmations: [confirmationJson()],
      location: '/order/konfirmasi/c1',
      extra: {
        'POST /v1/busboy/order-confirmations/c1/claim': (
          409,
          {
            'meta': {
              'success': false,
              'message':
                  'Confirmation could not be claimed. Another busboy may '
                  'have taken it first.',
              'code': 409,
              'trace_id': 'x',
            },
            'errors': null,
          },
        ),
      },
    );

    await tester.tap(find.text('Lanjutkan Pesanan'));
    await tester.pumpAndSettle();

    expect(find.text('Tugas ini sudah diambil busboy lain.'), findsOneWidget);
    expect(find.text('Detail Pesanan'), findsOneWidget);
  });
}

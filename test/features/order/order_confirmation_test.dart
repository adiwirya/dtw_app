import 'package:dio/dio.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/realtime/busboy_realtime_service.dart';
import 'package:dtw_app/features/order/data/models/order_confirmation.dart';
import 'package:dtw_app/features/order/data/repositories/busboy_confirmation_repository.dart';
import 'package:dtw_app/features/order/presentation/providers/order_confirmation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/busboy_board.dart';
import '../../support/fake_busboy_realtime_service.dart';
import '../../support/routed_dio.dart';

Map<String, dynamic> confirmationJson({
  String id = 'c1',
  String? busboyUserId,
  String? resolvedAt,
  List<Map<String, dynamic>>? items,
}) => {
  'id': id,
  'order_id': 'o1',
  'order_group_id': 'g1',
  'zone_id': 'z1',
  'busboy_user_id': busboyUserId,
  'status': 'PENDING',
  'decision': null,
  'table_number': 'A12',
  'customer_name': 'Budi Santoso',
  'receipt_number': 'RCP-1',
  'brand_name': 'KFC',
  'claimed_at': null,
  'resolved_at': resolvedAt,
  'created_at': '2026-10-09 10:03:00',
  'items':
      items ??
      [
        {
          'product_name': 'Es Teh',
          'quantity': 2,
          'rejected_quantity': 1,
          'status': 'PARTIALLY_ACCEPTED',
          'rejection_reason': 'Stok habis',
        },
        {
          'product_name': 'Nasi',
          'quantity': 1,
          'rejected_quantity': 0,
          'status': 'ACCEPTED',
          'rejection_reason': null,
        },
      ],
};

void main() {
  group('OrderConfirmation.fromJson', () {
    test('parses the live shape', () {
      final c = OrderConfirmation.fromJson(confirmationJson());

      expect(c.id, 'c1');
      expect(c.brandName, 'KFC');
      expect(c.customerName, 'Budi Santoso');
      expect(c.items, hasLength(2));
      expect(c.items.first.rejectedQuantity, 1);
      expect(c.items.first.rejectionReason, 'Stok habis');
      // Only the line with rejected units counts as "tidak tersedia".
      expect(c.rejectedCount, 1);
    });

    test('isOpenFor: free or mine and unresolved only', () {
      OrderConfirmation of(String? busboy, {String? resolvedAt}) =>
          OrderConfirmation.fromJson(
            confirmationJson(busboyUserId: busboy, resolvedAt: resolvedAt),
          );

      expect(of(null).isOpenFor('me'), isTrue);
      expect(of('me').isOpenFor('me'), isTrue);
      expect(of('other').isOpenFor('me'), isFalse);
      expect(
        of('me', resolvedAt: '2026-10-09 10:05:00').isOpenFor('me'),
        isFalse,
      );
    });
  });

  group('BusboyConfirmationRepository', () {
    test(
      'claim and resolve POST to the right paths with the decision',
      () async {
        final dio = routedDio({
          'POST /v1/busboy/order-confirmations/c1/claim': (
            200,
            busboyEnvelope(confirmationJson(busboyUserId: 'me')),
          ),
          'POST /v1/busboy/order-confirmations/c1/resolve': (
            200,
            busboyEnvelope(confirmationJson(busboyUserId: 'me')),
          ),
        });
        final repository = BusboyConfirmationRepository(dio: dio);

        await repository.claim('c1');
        await repository.resolve('c1', ConfirmationDecision.cancel);

        final adapter = dio.httpClientAdapter as RoutedAdapter;
        expect(adapter.requests.map((r) => r.path), [
          '/v1/busboy/order-confirmations/c1/claim',
          '/v1/busboy/order-confirmations/c1/resolve',
        ]);
        // Upper-case wire value, exactly as the API requires.
        expect(adapter.requests.last.data, {'decision': 'CANCEL'});
      },
    );
  });

  group('OrderConfirmationBoard', () {
    late FakeBusboyRealtimeService realtime;
    late ProviderContainer container;
    late Dio dio;

    ProviderContainer build(
      Map<String, (int, Object?)> responses, {
      String? me = 'me',
    }) {
      realtime = FakeBusboyRealtimeService();
      dio = routedDio(responses);
      container = ProviderContainer(
        overrides: [
          busboyConfirmationRepositoryProvider.overrideWithValue(
            BusboyConfirmationRepository(dio: dio),
          ),
          busboyRealtimeServiceProvider.overrideWithValue(realtime),
          sessionUserIdProvider.overrideWith((ref) => me),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(realtime.close);
      container.listen(orderConfirmationBoardProvider, (_, _) {});
      return container;
    }

    test('open list hides resolved and other busboys\' tasks', () async {
      build({
        'GET /v1/busboy/order-confirmations': (
          200,
          busboyEnvelope([
            confirmationJson(id: 'free'),
            confirmationJson(id: 'mine', busboyUserId: 'me'),
            confirmationJson(id: 'theirs', busboyUserId: 'other'),
            confirmationJson(id: 'done', resolvedAt: '2026-10-09 10:05:00'),
          ]),
        ),
      });
      await container.read(orderConfirmationBoardProvider.future);

      final open = container.read(openConfirmationsProvider);

      expect(open.map((c) => c.id), ['free', 'mine']);
    });

    test(
      'a created event adds the task; a resolved event removes it',
      () async {
        build({
          'GET /v1/busboy/order-confirmations': (200, busboyEnvelope([])),
        });
        await container.read(orderConfirmationBoardProvider.future);

        realtime.emitConfirmationCreated(confirmationJson(id: 'new'));
        await Future<void>.delayed(Duration.zero);
        expect(container.read(openConfirmationsProvider).map((c) => c.id), [
          'new',
        ]);

        realtime.emitConfirmationResolved(
          confirmationJson(id: 'new', resolvedAt: '2026-10-09 10:09:00'),
        );
        await Future<void>.delayed(Duration.zero);
        expect(container.read(openConfirmationsProvider), isEmpty);
      },
    );

    test('decide claims an unclaimed task before resolving it', () async {
      build({
        'GET /v1/busboy/order-confirmations': (
          200,
          busboyEnvelope([confirmationJson()]),
        ),
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
      });
      final board = await container.read(orderConfirmationBoardProvider.future);

      await container
          .read(orderConfirmationBoardProvider.notifier)
          .decide(board.single, ConfirmationDecision.proceed);

      final adapter = dio.httpClientAdapter as RoutedAdapter;
      expect(
        adapter.requests.where((r) => r.method == 'POST').map((r) => r.path),
        [
          '/v1/busboy/order-confirmations/c1/claim',
          '/v1/busboy/order-confirmations/c1/resolve',
        ],
      );
      expect(container.read(openConfirmationsProvider), isEmpty);
    });

    test('decide skips the claim when the task is already mine', () async {
      build({
        'GET /v1/busboy/order-confirmations': (
          200,
          busboyEnvelope([confirmationJson(busboyUserId: 'me')]),
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
      });
      final board = await container.read(orderConfirmationBoardProvider.future);

      await container
          .read(orderConfirmationBoardProvider.notifier)
          .decide(board.single, ConfirmationDecision.cancel);

      final adapter = dio.httpClientAdapter as RoutedAdapter;
      expect(
        adapter.requests.where((r) => r.method == 'POST').map((r) => r.path),
        ['/v1/busboy/order-confirmations/c1/resolve'],
      );
    });
  });
}

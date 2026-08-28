import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_order_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/canned_dio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('fetchOrders', () {
    test(
      'parses the live response shape and passes branch_id as a query param',
      () async {
        final dio = cannedDio(200, {
          'meta': {
            'success': true,
            'message': 'Success',
            'code': 200,
            'trace_id': 'abc'
          },
          'data': [
            {
              'id': 'order-1',
              'order_group_id': 'group-1',
              'branch_id': 'branch-1',
              'receipt_number': 'RCP-1',
              'grand_total': 21000,
              'order_status': 'PENDING',
              'created_at': '2026-08-07 09:24:08',
              'updated_at': '2026-08-07 09:24:08',
              'items': <dynamic>[],
            },
          ],
        });
        final repository = TenantOrderRepository(dio: dio);

        final orders = await repository.fetchOrders(branchId: 'branch-1');

        expect(orders, hasLength(1));
        expect(orders.single.id, 'order-1');
        expect(
          (dio.httpClientAdapter as CannedAdapter)
              .lastRequest!
              .queryParameters,
          {'branch_id': 'branch-1'},
        );
      },
    );

    test(
      'throws ApiException with the required-field message on 422',
      () async {
        final dio = cannedDio(422, {
          'meta': {
            'success': false,
            'message': 'Validation failed.',
            'code': 422,
            'trace_id': 'abc'
          },
          'errors': {
            'branch_id': ['The branch id field is required.'],
          },
        });
        final repository = TenantOrderRepository(dio: dio);

        await expectLater(
          repository.fetchOrders(branchId: 'branch-1'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'The branch id field is required.',
            ),
          ),
        );
      },
    );
  });

  group('updateStatus', () {
    test(
      'PATCHes order_status with the wire enum value',
      () async {
        final dio = cannedDio(200, {
          'meta': {
            'success': true,
            'message': 'Success',
            'code': 200,
            'trace_id': 'abc'
          },
        });
        final repository = TenantOrderRepository(dio: dio);

        await repository.updateStatus(
          'order-1',
          status: TenantOrderStatus.preparing,
        );

        final adapter = dio.httpClientAdapter as CannedAdapter;
        expect(adapter.lastRequest!.path, '/v1/orders/order-1/status');
        expect(adapter.lastRequest!.method, 'PATCH');
        expect(adapter.lastRequest!.data, {'order_status': 'PREPARING'});
      },
    );

    test(
      'throws a mapped ApiException on failure',
      () async {
        final dio = cannedDio(500, {
          'meta': {
            'success': false,
            'message': 'Error',
            'code': 500,
            'trace_id': 'abc'
          },
        });
        final repository = TenantOrderRepository(dio: dio);

        await expectLater(
          repository.updateStatus(
            'order-1',
            status: TenantOrderStatus.preparing,
          ),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'Terjadi kesalahan. Coba lagi.',
            ),
          ),
        );
      },
    );
  });

  group('processOrder', () {
    test(
      'POSTs rejected_item_ids to /process',
      () async {
        final dio = cannedDio(200, {
          'meta': {
            'success': true,
            'message': 'Success',
            'code': 200,
            'trace_id': 'abc',
          },
        });
        final repository = TenantOrderRepository(dio: dio);

        await repository.processOrder(
          'order-1',
          rejectedItemIds: ['item-1', 'item-2'],
        );

        final adapter = dio.httpClientAdapter as CannedAdapter;
        expect(adapter.lastRequest!.path, '/v1/orders/order-1/process');
        expect(adapter.lastRequest!.method, 'POST');
        expect(adapter.lastRequest!.data, {
          'rejected_item_ids': ['item-1', 'item-2'],
        });
      },
    );

    test(
      'sends an empty list to accept every item',
      () async {
        final dio = cannedDio(200, {
          'meta': {
            'success': true,
            'message': 'Success',
            'code': 200,
            'trace_id': 'abc',
          },
        });
        final repository = TenantOrderRepository(dio: dio);

        await repository.processOrder('order-1', rejectedItemIds: const []);

        final adapter = dio.httpClientAdapter as CannedAdapter;
        expect(adapter.lastRequest!.data, {'rejected_item_ids': <String>[]});
      },
    );

    test(
      'throws a mapped ApiException on failure (e.g. order no longer PENDING)',
      () async {
        final dio = cannedDio(400, {
          'meta': {
            'success': false,
            'message': 'Error',
            'code': 400,
            'trace_id': 'abc',
          },
        });
        final repository = TenantOrderRepository(dio: dio);

        await expectLater(
          repository.processOrder('order-1', rejectedItemIds: const []),
          throwsA(isA<ApiException>()),
        );
      },
    );
  });

  group('fetchMissedEvents', () {
    test(
      'passes branch_id and after_id as query params',
      () async {
        final dio = cannedDio(200, {
          'meta': {
            'success': true,
            'message': 'Success',
            'code': 200,
            'trace_id': 'abc'
          },
          'data': <dynamic>[],
        });
        final repository = TenantOrderRepository(dio: dio);

        final orders = await repository.fetchMissedEvents(
          branchId: 'branch-1',
          afterId: 42,
        );

        expect(orders, isEmpty);
        expect(
          (dio.httpClientAdapter as CannedAdapter)
              .lastRequest!
              .queryParameters,
          {'branch_id': 'branch-1', 'after_id': 42},
        );
      },
    );

    test(
      'unwraps each item\'s order/order_group-nested payload '
      '(confirmed live shape: {id, event, payload, created_at})',
      () async {
        final dio = cannedDio(200, {
          'meta': {
            'success': true,
            'message': 'Success',
            'code': 200,
            'trace_id': 'abc',
          },
          'data': [
            {
              'id': 'event-1',
              'event': 'order.created',
              'created_at': '2026-08-26 08:54:20',
              'payload': {
                'broadcast_event_id': 42,
                'order_group': {'table_number': 'A-01'},
                'order': {
                  'id': 'order-1',
                  'order_group_id': 'group-1',
                  'branch_id': 'branch-1',
                  'receipt_number': 'RCP-1',
                  'grand_total': 10000,
                  'order_status': 'PENDING',
                  'table_number': null,
                  'created_at': '2026-08-26 08:54:20',
                  'updated_at': '2026-08-26 08:54:21',
                  'items': <dynamic>[],
                },
              },
            },
          ],
        });
        final repository = TenantOrderRepository(dio: dio);

        final orders = await repository.fetchMissedEvents(
          branchId: 'branch-1',
          afterId: 41,
        );

        expect(orders, hasLength(1));
        expect(orders.single.id, 'order-1');
        expect(orders.single.tableNumber, 'A-01');
        expect(orders.single.broadcastEventId, 42);
      },
    );
  });
}

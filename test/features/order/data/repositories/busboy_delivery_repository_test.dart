import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/features/order/data/models/delivery.dart';
import 'package:dtw_app/features/order/data/repositories/busboy_delivery_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/busboy_board.dart';
import '../../../../support/canned_dio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('fetchDeliveries', () {
    test('parses the live response shape', () async {
      final dio = cannedDeliveryListDio([
        deliveryJson(id: 'delivery-1', status: 'PENDING_PICKUP'),
      ]);
      final repository = BusboyDeliveryRepository(dio: dio);

      final deliveries = await repository.fetchDeliveries();

      expect(deliveries, hasLength(1));
      expect(deliveries.single.id, 'delivery-1');
      expect(deliveries.single.status, DeliveryStatus.pendingPickup);
    });

    test('passes status as a query param when given', () async {
      final dio = cannedDeliveryListDio([]);
      final repository = BusboyDeliveryRepository(dio: dio);

      await repository.fetchDeliveries(status: DeliveryStatus.claimed);

      final adapter = dio.httpClientAdapter as CannedAdapter;
      expect(adapter.lastRequest!.path, '/v1/busboy/deliveries');
      expect(adapter.lastRequest!.queryParameters, {'status': 'CLAIMED'});
    });

    test('omits the status query param when not given', () async {
      final dio = cannedDeliveryListDio([]);
      final repository = BusboyDeliveryRepository(dio: dio);

      await repository.fetchDeliveries();

      final adapter = dio.httpClientAdapter as CannedAdapter;
      expect(adapter.lastRequest!.queryParameters, isEmpty);
    });

    test('throws a mapped ApiException on failure', () async {
      final dio = cannedDio(500, {
        'meta': {
          'success': false,
          'message': 'Error',
          'code': 500,
          'trace_id': 'abc',
        },
      });
      final repository = BusboyDeliveryRepository(dio: dio);

      await expectLater(
        repository.fetchDeliveries(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('claim', () {
    test('POSTs to the claim endpoint', () async {
      final dio = cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Success',
          'code': 200,
          'trace_id': 'abc',
        },
      });
      final repository = BusboyDeliveryRepository(dio: dio);

      await repository.claim('delivery-1');

      final adapter = dio.httpClientAdapter as CannedAdapter;
      expect(adapter.lastRequest!.path, '/v1/busboy/deliveries/delivery-1/claim');
      expect(adapter.lastRequest!.method, 'POST');
    });

    test('throws a mapped ApiException on failure', () async {
      final dio = cannedDio(400, {
        'meta': {
          'success': false,
          'message': 'Error',
          'code': 400,
          'trace_id': 'abc',
        },
      });
      final repository = BusboyDeliveryRepository(dio: dio);

      await expectLater(
        repository.claim('delivery-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('complete', () {
    test('POSTs to the complete endpoint', () async {
      final dio = cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Success',
          'code': 200,
          'trace_id': 'abc',
        },
      });
      final repository = BusboyDeliveryRepository(dio: dio);

      await repository.complete('delivery-1');

      final adapter = dio.httpClientAdapter as CannedAdapter;
      expect(
        adapter.lastRequest!.path,
        '/v1/busboy/deliveries/delivery-1/complete',
      );
      expect(adapter.lastRequest!.method, 'POST');
    });
  });
}

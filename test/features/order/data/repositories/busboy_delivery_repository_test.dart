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

  group('fetchHistory', () {
    test('parses the live response shape', () async {
      final dio = cannedDeliveryListDio([
        deliveryJson(id: 'delivery-1', status: 'DELIVERED'),
      ]);
      final repository = BusboyDeliveryRepository(dio: dio);

      final deliveries = await repository.fetchHistory();

      expect(deliveries, hasLength(1));
      expect(deliveries.single.id, 'delivery-1');
      final adapter = dio.httpClientAdapter as CannedAdapter;
      expect(adapter.lastRequest!.path, '/v1/busboy/deliveries/history');
    });

    test('passes status as a query param when given', () async {
      final dio = cannedDeliveryListDio([]);
      final repository = BusboyDeliveryRepository(dio: dio);

      await repository.fetchHistory(status: DeliveryStatus.delivered);

      final adapter = dio.httpClientAdapter as CannedAdapter;
      expect(adapter.lastRequest!.queryParameters, {'status': 'DELIVERED'});
    });

    test('omits the status query param when not given', () async {
      final dio = cannedDeliveryListDio([]);
      final repository = BusboyDeliveryRepository(dio: dio);

      await repository.fetchHistory();

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
        repository.fetchHistory(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('fetchRating', () {
    test('parses the average and count from the rating payload', () async {
      final dio = cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Success',
          'code': 200,
          'trace_id': 'abc',
        },
        'data': {'average': 4.8, 'count': 30},
      });
      final repository = BusboyDeliveryRepository(dio: dio);

      final rating = await repository.fetchRating(userId: 'user-1');

      expect(rating.average, 4.8);
      expect(rating.count, 30);
      expect(
        (dio.httpClientAdapter as CannedAdapter).lastRequest!.path,
        '/v1/busboys/user-1/rating',
      );
    });

    test('a null average (no ratings yet) is not coerced to 0', () async {
      final dio = cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Success',
          'code': 200,
          'trace_id': 'abc',
        },
        'data': {'average': null, 'count': 0},
      });
      final repository = BusboyDeliveryRepository(dio: dio);

      final rating = await repository.fetchRating(userId: 'user-1');

      expect(rating.average, isNull);
      expect(rating.count, 0);
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
        repository.fetchRating(userId: 'user-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

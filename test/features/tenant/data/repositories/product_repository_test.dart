import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/features/tenant/data/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/canned_dio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('fetchProducts', () {
    test(
      'parses the live response shape and passes brand_id as a query param',
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
              'id': 'product-1',
              'brand_id': 'brand-1',
              'brand_name': 'Janji Jiwa',
              'category_id': 'cat-1',
              'category_name': 'Sahabat Series',
              'sku': null,
              'name': 'Sahabat Latte',
              'description': null,
              'tags': null,
              'dpp_price': 17927.93,
              'pb1_percentage': 11,
              'pb1_price': 1972.07,
              'total_price': 19900,
              'image_url': null,
              'is_active': true,
              'created_at': '2026-08-07 09:16:59',
              'updated_at': '2026-08-07 09:16:59',
            },
          ],
        });
        final repository = ProductRepository(dio: dio);

        final products = await repository.fetchProducts(brandId: 'brand-1');

        expect(products, hasLength(1));
        expect(products.single.id, 'product-1');
        expect(products.single.name, 'Sahabat Latte');
        expect(products.single.totalPrice, 19900);
        expect(
          (dio.httpClientAdapter as CannedAdapter).lastRequest!.queryParameters,
          {'brand_id': 'brand-1'},
        );
      },
    );

    test('throws a mapped ApiException on failure', () async {
      final dio = cannedDio(500, {
        'meta': {
          'success': false,
          'message': 'Error',
          'code': 500,
          'trace_id': 'abc',
        },
      });
      final repository = ProductRepository(dio: dio);

      await expectLater(
        repository.fetchProducts(brandId: 'brand-1'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Terjadi kesalahan. Coba lagi.',
          ),
        ),
      );
    });
  });

  group('fetchAvailability', () {
    test('keys the lightweight availability list by product id', () async {
      final dio = cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Success',
          'code': 200,
          'trace_id': 'abc',
        },
        'data': [
          {
            'id': 'product-1',
            'name': 'Sahabat Latte',
            'total_price': 19900,
            'category_id': 'cat-1',
            'category_name': 'Sahabat Series',
            'is_available': false,
          },
        ],
      });
      final repository = ProductRepository(dio: dio);

      final availability =
          await repository.fetchAvailability(branchId: 'branch-1');

      expect(availability, {'product-1': false});
      expect(
        (dio.httpClientAdapter as CannedAdapter).lastRequest!.path,
        '/v1/tenant-branches/branch-1/product-availability',
      );
    });
  });

  group('updateAvailability', () {
    test('PATCHes is_available to the branch-scoped endpoint', () async {
      final dio = cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Success',
          'code': 200,
          'trace_id': 'abc',
        },
        'data': null,
      });
      final repository = ProductRepository(dio: dio);

      await repository.updateAvailability(
        'product-1',
        branchId: 'branch-1',
        isAvailable: false,
      );

      final adapter = dio.httpClientAdapter as CannedAdapter;
      expect(
        adapter.lastRequest!.path,
        '/v1/tenant-branches/branch-1/product-availability/product-1',
      );
      expect(adapter.lastRequest!.method, 'PATCH');
      expect(adapter.lastRequest!.data, {'is_available': false});
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
      final repository = ProductRepository(dio: dio);

      await expectLater(
        repository.updateAvailability(
          'product-1',
          branchId: 'branch-1',
          isAvailable: false,
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

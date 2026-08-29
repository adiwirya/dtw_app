import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/features/tenant/data/repositories/modifier_group_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/canned_dio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('fetchModifierGroups', () {
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
              'id': 'group-1',
              'brand_id': 'brand-1',
              'brand_name': 'Janji Jiwa',
              'name': 'Tingkat Pedas',
              'description': 'Pilih level',
              'is_required': true,
              'min_selections': 1,
              'max_selections': 1,
              'sequence_order': 1,
              'is_active': true,
              'option_count': 2,
              'created_at': '2026-08-13 11:01:33',
              'updated_at': '2026-08-13 11:01:33',
            },
          ],
        });
        final repository = ModifierGroupRepository(dio: dio);

        final groups =
            await repository.fetchModifierGroups(brandId: 'brand-1');

        expect(groups, hasLength(1));
        expect(groups.single.id, 'group-1');
        expect(groups.single.name, 'Tingkat Pedas');
        expect(groups.single.isRequired, isTrue);
        expect(groups.single.maxSelections, 1);
        expect(groups.single.optionCount, 2);
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
      final repository = ModifierGroupRepository(dio: dio);

      await expectLater(
        repository.fetchModifierGroups(brandId: 'brand-1'),
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

  group('createModifierGroup', () {
    test('POSTs brand_id/name/min_selections/max_selections and parses the '
        'created group', () async {
      final dio = cannedDio(201, {
        'meta': {
          'success': true,
          'message': 'Modifier group created successfully.',
          'code': 201,
          'trace_id': 'abc',
        },
        'data': {
          'id': 'group-1',
          'brand_id': 'brand-1',
          'brand_name': 'Janji Jiwa',
          'name': 'Tingkat Pedas',
          'description': 'Pilih level',
          'is_required': true,
          'min_selections': 1,
          'max_selections': 1,
          'sequence_order': 1,
          'is_active': true,
          'option_count': 0,
          'created_at': '2026-08-13 11:01:33',
          'updated_at': '2026-08-13 11:01:33',
        },
      });
      final repository = ModifierGroupRepository(dio: dio);

      final group = await repository.createModifierGroup(
        brandId: 'brand-1',
        name: 'Tingkat Pedas',
        minSelections: 1,
        maxSelections: 1,
      );

      expect(group.id, 'group-1');
      final adapter = dio.httpClientAdapter as CannedAdapter;
      expect(adapter.lastRequest!.path, '/v1/modifier-groups');
      expect(adapter.lastRequest!.method, 'POST');
      expect(adapter.lastRequest!.data, {
        'brand_id': 'brand-1',
        'name': 'Tingkat Pedas',
        'min_selections': 1,
        'max_selections': 1,
      });
    });

    test('throws a mapped ApiException on failure', () async {
      final dio = cannedDio(422, {
        'meta': {
          'success': false,
          'message': 'Validation failed.',
          'code': 422,
          'trace_id': 'abc',
        },
        'errors': {
          'name': ['The name field is required.'],
        },
      });
      final repository = ModifierGroupRepository(dio: dio);

      await expectLater(
        repository.createModifierGroup(
          brandId: 'brand-1',
          name: '',
          minSelections: 0,
          maxSelections: 1,
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'The name field is required.',
          ),
        ),
      );
    });
  });

  group('addOption', () {
    test('POSTs name/price to the group-scoped endpoint', () async {
      final dio = cannedDio(201, {
        'meta': {
          'success': true,
          'message': 'Modifier option created successfully.',
          'code': 201,
          'trace_id': 'abc',
        },
        'data': {
          'id': 'option-1',
          'modifier_group_id': 'group-1',
          'name': 'Original',
          'dpp_price': 0,
          'pb1_percentage': 11,
          'pb1_price': 0,
          'total_price': 0,
          'sequence_order': 1,
          'created_at': '2026-08-13 11:01:34',
          'updated_at': '2026-08-13 11:01:34',
        },
      });
      final repository = ModifierGroupRepository(dio: dio);

      await repository.addOption('group-1', name: 'Original', price: 0);

      final adapter = dio.httpClientAdapter as CannedAdapter;
      expect(adapter.lastRequest!.path, '/v1/modifier-groups/group-1/options');
      expect(adapter.lastRequest!.method, 'POST');
      expect(adapter.lastRequest!.data, {'name': 'Original', 'price': 0});
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
      final repository = ModifierGroupRepository(dio: dio);

      await expectLater(
        repository.addOption('group-1', name: 'Original', price: 0),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('fetchModifierGroup', () {
    test('GETs the group-scoped endpoint and parses its options', () async {
      final dio = cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Success',
          'code': 200,
          'trace_id': 'abc',
        },
        'data': {
          'id': 'group-1',
          'brand_id': 'brand-1',
          'brand_name': 'Janji Jiwa',
          'name': 'Ukuran Minuman',
          'description': null,
          'is_required': true,
          'min_selections': 1,
          'max_selections': 1,
          'sequence_order': 1,
          'is_active': true,
          'option_count': 1,
          'created_at': '2026-08-13 11:01:33',
          'updated_at': '2026-08-13 11:01:33',
          'options': [
            {
              'id': 'option-1',
              'modifier_group_id': 'group-1',
              'name': 'Small',
              'dpp_price': 0,
              'pb1_percentage': 11,
              'pb1_price': 0,
              'total_price': 0,
              'sequence_order': 1,
              'created_at': '2026-08-13 11:01:34',
              'updated_at': '2026-08-13 11:01:34',
            },
          ],
        },
      });
      final repository = ModifierGroupRepository(dio: dio);

      final group = await repository.fetchModifierGroup('group-1');

      expect(group.id, 'group-1');
      expect(group.name, 'Ukuran Minuman');
      expect(group.options, hasLength(1));
      expect(group.options!.single.id, 'option-1');
      expect(group.options!.single.name, 'Small');
      final adapter = dio.httpClientAdapter as CannedAdapter;
      expect(adapter.lastRequest!.path, '/v1/modifier-groups/group-1');
      expect(adapter.lastRequest!.method, 'GET');
    });

    test('throws a mapped ApiException on failure', () async {
      final dio = cannedDio(404, {
        'meta': {
          'success': false,
          'message': 'Not found.',
          'code': 404,
          'trace_id': 'abc',
        },
      });
      final repository = ModifierGroupRepository(dio: dio);

      await expectLater(
        repository.fetchModifierGroup('group-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('updateModifierGroup', () {
    test('PUTs name/rules/is_active and parses the updated group', () async {
      final dio = cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Modifier group updated successfully.',
          'code': 200,
          'trace_id': 'abc',
        },
        'data': {
          'id': 'group-1',
          'brand_id': 'brand-1',
          'brand_name': 'Janji Jiwa',
          'name': 'Ukuran Minuman Baru',
          'description': null,
          'is_required': false,
          'min_selections': 0,
          'max_selections': 2,
          'sequence_order': 1,
          'is_active': true,
          'option_count': 0,
          'created_at': '2026-08-13 11:01:33',
          'updated_at': '2026-08-13 11:05:00',
        },
      });
      final repository = ModifierGroupRepository(dio: dio);

      final group = await repository.updateModifierGroup(
        'group-1',
        name: 'Ukuran Minuman Baru',
        minSelections: 0,
        maxSelections: 2,
        isActive: true,
      );

      expect(group.name, 'Ukuran Minuman Baru');
      final adapter = dio.httpClientAdapter as CannedAdapter;
      expect(adapter.lastRequest!.path, '/v1/modifier-groups/group-1');
      expect(adapter.lastRequest!.method, 'PUT');
      expect(adapter.lastRequest!.data, {
        'name': 'Ukuran Minuman Baru',
        'min_selections': 0,
        'max_selections': 2,
        'is_active': true,
      });
    });

    test('throws a mapped ApiException on failure', () async {
      final dio = cannedDio(422, {
        'meta': {
          'success': false,
          'message': 'The is active field is required.',
          'code': 422,
          'trace_id': 'abc',
        },
      });
      final repository = ModifierGroupRepository(dio: dio);

      await expectLater(
        repository.updateModifierGroup(
          'group-1',
          name: 'Ukuran Minuman Baru',
          minSelections: 0,
          maxSelections: 2,
          isActive: true,
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('reorderOptions', () {
    test('POSTs the ids in order', () async {
      final dio = cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Success',
          'code': 200,
          'trace_id': 'abc',
        },
      });
      final repository = ModifierGroupRepository(dio: dio);

      await repository.reorderOptions(
        'group-1',
        optionIds: ['option-2', 'option-1'],
      );

      final adapter = dio.httpClientAdapter as CannedAdapter;
      expect(
        adapter.lastRequest!.path,
        '/v1/modifier-groups/group-1/options/reorder',
      );
      expect(adapter.lastRequest!.method, 'POST');
      expect(adapter.lastRequest!.data, {
        'ids': ['option-2', 'option-1'],
      });
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
      final repository = ModifierGroupRepository(dio: dio);

      await expectLater(
        repository.reorderOptions('group-1', optionIds: ['option-1']),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('updateOption', () {
    test('PUTs name/price to the option-scoped endpoint', () async {
      final dio = cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Modifier option updated successfully.',
          'code': 200,
          'trace_id': 'abc',
        },
        'data': {
          'id': 'option-1',
          'modifier_group_id': 'group-1',
          'name': 'Medium',
          'dpp_price': 0,
          'pb1_percentage': 11,
          'pb1_price': 0,
          'total_price': 3000,
          'sequence_order': 1,
          'created_at': '2026-08-13 11:01:34',
          'updated_at': '2026-08-13 11:05:00',
        },
      });
      final repository = ModifierGroupRepository(dio: dio);

      await repository.updateOption(
        'group-1',
        'option-1',
        name: 'Medium',
        price: 3000,
      );

      final adapter = dio.httpClientAdapter as CannedAdapter;
      expect(
        adapter.lastRequest!.path,
        '/v1/modifier-groups/group-1/options/option-1',
      );
      expect(adapter.lastRequest!.method, 'PUT');
      expect(adapter.lastRequest!.data, {'name': 'Medium', 'price': 3000});
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
      final repository = ModifierGroupRepository(dio: dio);

      await expectLater(
        repository.updateOption(
          'group-1',
          'option-1',
          name: 'Medium',
          price: 3000,
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

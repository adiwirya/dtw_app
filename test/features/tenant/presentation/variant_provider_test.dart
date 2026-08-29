import 'package:dtw_app/features/tenant/data/models/tenant_branch.dart';
import 'package:dtw_app/features/tenant/data/repositories/modifier_group_repository.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
import 'package:dtw_app/features/tenant/presentation/providers/variant_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/variant_rows.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/canned_dio.dart';
import '../../../support/routed_dio.dart';

TenantBranch _testBranch() => TenantBranch(
      id: 'branch-1',
      brandId: 'brand-1',
      brandName: 'Janji Jiwa',
      branchName: 'Janji Jiwa',
      areaName: 'Downtown',
      isActive: true,
      createdAt: DateTime(2026, 8, 7),
    );

Map<String, dynamic> _groupsEnvelope(List<Map<String, dynamic>> items) => {
      'meta': {
        'success': true,
        'message': 'Success',
        'code': 200,
        'trace_id': 'abc',
      },
      'data': items,
    };

Map<String, dynamic> _group(
  String id,
  String name, {
  required int maxSelections,
  required int optionCount,
}) =>
    {
      'id': id,
      'brand_id': 'brand-1',
      'brand_name': 'Janji Jiwa',
      'name': name,
      'description': null,
      'is_required': true,
      'min_selections': 1,
      'max_selections': maxSelections,
      'sequence_order': 1,
      'is_active': true,
      'option_count': optionCount,
      'created_at': '2026-08-13 11:01:33',
      'updated_at': '2026-08-13 11:01:33',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer buildContainer({required int statusCode, Object? body}) {
    final container = ProviderContainer(
      overrides: [
        currentTenantBranchProvider.overrideWith((ref) async => _testBranch()),
        modifierGroupRepositoryProvider.overrideWithValue(
          ModifierGroupRepository(dio: cannedDio(statusCode, body)),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('VariantList', () {
    test(
        'fetches modifier groups for the current brand and derives '
        'Tunggal/Ganda from max_selections', () async {
      final container = buildContainer(
        statusCode: 200,
        body: _groupsEnvelope([
          _group('group-1', 'Tingkat Pedas', maxSelections: 1, optionCount: 2),
          _group('group-2', 'Extra Topping', maxSelections: 3, optionCount: 5),
        ]),
      );

      final variants = await container.read(variantListProvider.future);

      expect(variants, hasLength(2));
      expect(variants[0].id, 'group-1');
      expect(variants[0].name, 'Tingkat Pedas');
      expect(variants[0].type, VariantType.tunggal);
      expect(variants[0].optionCount, 2);
      // The list endpoint has no option names, only the count.
      expect(variants[0].options, isNull);
      expect(variants[1].type, VariantType.ganda);
    });

    test('starts empty when the brand has no modifier groups yet', () async {
      final container = buildContainer(
        statusCode: 200,
        body: _groupsEnvelope([]),
      );

      final variants = await container.read(variantListProvider.future);

      expect(variants, isEmpty);
    });

    test(
        'create posts the group then each option in sequence, appending the '
        'result locally without a refetch', () async {
      final dio = routedDio({
        // The initial build() fetch (GET, list shape).
        'GET /v1/modifier-groups': (200, _groupsEnvelope([])),
        'POST /v1/modifier-groups/group-1/options': (
          201,
          _groupsEnvelope([]), // body content unused by addOption
        ),
        'POST /v1/modifier-groups': (
          201,
          {
            'meta': {
              'success': true,
              'message': 'Modifier group created successfully.',
              'code': 201,
              'trace_id': 'abc',
            },
            'data': _group(
              'group-1',
              'Tingkat Pedas',
              maxSelections: 1,
              optionCount: 0,
            ),
          },
        ),
      });
      final container = ProviderContainer(
        overrides: [
          currentTenantBranchProvider.overrideWith(
            (ref) async => _testBranch(),
          ),
          modifierGroupRepositoryProvider.overrideWithValue(
            ModifierGroupRepository(dio: dio),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(variantListProvider, (_, _) {});
      await container.read(variantListProvider.future);

      await container.read(variantListProvider.notifier).create(
            name: 'Tingkat Pedas',
            isRequired: true,
            multiSelect: false,
            options: const [
              VariantOptionData(name: 'Original'),
              VariantOptionData(name: 'Spicy', addonPrice: 'Rp2.000'),
            ],
          );

      final variants = container.read(variantListProvider).value!;
      expect(variants, hasLength(1));
      expect(variants.single.id, 'group-1');
      expect(variants.single.name, 'Tingkat Pedas');
      expect(variants.single.options, hasLength(2));
      expect(variants.single.options!.last.addonPrice, 'Rp2.000');

      final adapter = dio.httpClientAdapter as RoutedAdapter;
      expect(adapter.lastRequest!.path, '/v1/modifier-groups/group-1/options');
    });

    // The form lets the tenant drag option rows; that order has to reach the
    // server. Only already-saved options can be addressed by id.
    test('updateVariant persists the option order for saved options',
        () async {
      final dio = routedDio({
        'POST /v1/modifier-groups/group-1/options/reorder': (
          200,
          _groupsEnvelope([]),
        ),
        'GET /v1/modifier-groups/group-1': (
          200,
          {
            'meta': {
              'success': true,
              'message': 'Success',
              'code': 200,
              'trace_id': 'abc',
            },
            'data': {
              ..._group('group-1', 'Ukuran', maxSelections: 2, optionCount: 2),
              'options': <dynamic>[],
            },
          },
        ),
        'PUT /v1/modifier-groups/group-1/options/': (
          200,
          _groupsEnvelope([]),
        ),
        'PUT /v1/modifier-groups/group-1': (
          200,
          {
            'meta': {
              'success': true,
              'message': 'Success',
              'code': 200,
              'trace_id': 'abc',
            },
            'data': _group('group-1', 'Ukuran', maxSelections: 2,
                optionCount: 2),
          },
        ),
        'GET /v1/modifier-groups': (200, _groupsEnvelope([])),
      });
      final container = ProviderContainer(
        overrides: [
          currentTenantBranchProvider.overrideWith(
            (ref) async => _testBranch(),
          ),
          modifierGroupRepositoryProvider.overrideWithValue(
            ModifierGroupRepository(dio: dio),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(variantListProvider, (_, _) {});
      await container.read(variantListProvider.future);

      // Large first, Small second — the reverse of how they were created.
      await container.read(variantListProvider.notifier).updateVariant(
            groupId: 'group-1',
            name: 'Ukuran',
            isRequired: true,
            multiSelect: true,
            options: const [
              VariantOptionData(id: 'option-2', name: 'Large'),
              VariantOptionData(id: 'option-1', name: 'Small'),
            ],
          );

      final adapter = dio.httpClientAdapter as RoutedAdapter;
      final reorder = adapter.requests.firstWhere(
        (r) => r.path.endsWith('/options/reorder'),
      );
      expect(reorder.data, {'ids': ['option-2', 'option-1']});
    });

    test(
        'updateVariant PUTs the group and each already-saved option, POSTs '
        'each new option, then refetches the group for the final state',
        () async {
      final dio = routedDio({
        // More specific keys first — RoutedAdapter matches the first key
        // that's a prefix of "METHOD path", and 'GET /v1/modifier-groups'
        // (the list fetch) is itself a prefix of the detail-fetch path below.
        'GET /v1/modifier-groups/group-1': (
          200,
          {
            'meta': {
              'success': true,
              'message': 'Success',
              'code': 200,
              'trace_id': 'abc',
            },
            'data': {
              ..._group(
                'group-1',
                'Ukuran Minuman Baru',
                maxSelections: 2,
                optionCount: 2,
              ),
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
                  'updated_at': '2026-08-13 11:05:00',
                },
                {
                  'id': 'option-2',
                  'modifier_group_id': 'group-1',
                  'name': 'Large',
                  'dpp_price': 0,
                  'pb1_percentage': 11,
                  'pb1_price': 0,
                  'total_price': 5000,
                  'sequence_order': 2,
                  'created_at': '2026-08-13 11:05:00',
                  'updated_at': '2026-08-13 11:05:00',
                },
              ],
            },
          },
        ),
        'PUT /v1/modifier-groups/group-1/options/option-1': (
          200,
          _groupsEnvelope([]), // body content unused by updateOption
        ),
        'POST /v1/modifier-groups/group-1/options/reorder': (
          200,
          _groupsEnvelope([]),
        ),
        'POST /v1/modifier-groups/group-1/options': (
          201,
          _groupsEnvelope([]), // body content unused by addOption
        ),
        'PUT /v1/modifier-groups/group-1': (
          200,
          {
            'meta': {
              'success': true,
              'message': 'Modifier group updated successfully.',
              'code': 200,
              'trace_id': 'abc',
            },
            'data': _group(
              'group-1',
              'Ukuran Minuman Baru',
              maxSelections: 2,
              optionCount: 2,
            ),
          },
        ),
        // The initial build() fetch (GET, list shape) — least specific, last.
        'GET /v1/modifier-groups': (
          200,
          _groupsEnvelope([
            _group(
              'group-1',
              'Ukuran Minuman',
              maxSelections: 1,
              optionCount: 1,
            ),
          ]),
        ),
      });
      final container = ProviderContainer(
        overrides: [
          currentTenantBranchProvider.overrideWith(
            (ref) async => _testBranch(),
          ),
          modifierGroupRepositoryProvider.overrideWithValue(
            ModifierGroupRepository(dio: dio),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(variantListProvider, (_, _) {});
      await container.read(variantListProvider.future);

      await container.read(variantListProvider.notifier).updateVariant(
            groupId: 'group-1',
            name: 'Ukuran Minuman Baru',
            isRequired: true,
            multiSelect: true,
            options: const [
              VariantOptionData(id: 'option-1', name: 'Small'),
              VariantOptionData(name: 'Large', addonPrice: 'Rp5.000'),
            ],
          );

      final variants = container.read(variantListProvider).value!;
      expect(variants, hasLength(1));
      expect(variants.single.name, 'Ukuran Minuman Baru');
      expect(variants.single.options, hasLength(2));
      expect(variants.single.options![0].id, 'option-1');
      expect(variants.single.options![1].id, 'option-2');
      expect(variants.single.options![1].addonPrice, 'Rp5.000');

      final adapter = dio.httpClientAdapter as RoutedAdapter;
      final methodsAndPaths = [
        for (final r in adapter.requests) '${r.method} ${r.path}',
      ];
      expect(
        methodsAndPaths,
        containsAllInOrder([
          'PUT /v1/modifier-groups/group-1',
          'PUT /v1/modifier-groups/group-1/options/option-1',
          'POST /v1/modifier-groups/group-1/options',
          'GET /v1/modifier-groups/group-1',
        ]),
      );
      // Only one option was already saved, so there is nothing to reorder.
      expect(
        methodsAndPaths.where((p) => p.endsWith('/options/reorder')),
        isEmpty,
      );
    });
  });
}

import 'package:dtw_app/features/tenant/data/models/tenant_branch.dart';
import 'package:dtw_app/features/tenant/data/repositories/product_repository.dart';
import 'package:dtw_app/features/tenant/presentation/providers/menu_provider.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_item_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

Map<String, dynamic> _productsEnvelope(List<Map<String, dynamic>> items) => {
      'meta': {
        'success': true,
        'message': 'Success',
        'code': 200,
        'trace_id': 'abc',
      },
      'data': items,
    };

Map<String, dynamic> _product(String id, String name, int price) => {
      'id': id,
      'brand_id': 'brand-1',
      'brand_name': 'Janji Jiwa',
      'category_id': 'cat-1',
      'category_name': 'Sahabat Series',
      'sku': null,
      'name': name,
      'description': null,
      'tags': null,
      'dpp_price': price * 0.9,
      'pb1_percentage': 11,
      'pb1_price': price * 0.1,
      'total_price': price,
      'image_url': null,
      'is_active': true,
      'created_at': '2026-08-07 09:16:59',
      'updated_at': '2026-08-07 09:16:59',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer buildContainer({
    required Map<String, bool> availability,
  }) {
    final dio = routedDio({
      '/v1/tenant-branches/branch-1/product-availability': (
        200,
        _productsEnvelope([
          for (final entry in availability.entries)
            {'id': entry.key, 'is_available': entry.value},
        ]),
      ),
      '/v1/products': (
        200,
        _productsEnvelope([
          _product('product-1', 'Sahabat Latte', 19900),
          _product('product-2', 'Sahabat Hazelnut Latte', 21000),
        ]),
      ),
    });
    final container = ProviderContainer(
      overrides: [
        currentTenantBranchProvider.overrideWith((ref) async => _testBranch()),
        productRepositoryProvider.overrideWithValue(
          ProductRepository(dio: dio),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('MenuList', () {
    test('fetches products for the current branch and merges availability',
        () async {
      final container = buildContainer(
        availability: {'product-1': true, 'product-2': false},
      );

      final menus = await container.read(menuListProvider.future);

      expect(menus, hasLength(2));
      expect(menus[0].id, 'product-1');
      expect(menus[0].name, 'Sahabat Latte');
      expect(menus[0].price, 'Rp19.900');
      expect(menus[0].active, isTrue);
      expect(menus[1].active, isFalse);
    });

    test('setActive optimistically flips the row then confirms via PATCH',
        () async {
      final container = buildContainer(
        availability: {'product-1': true, 'product-2': true},
      );
      container.listen(menuListProvider, (_, _) {});
      await container.read(menuListProvider.future);

      await container
          .read(menuListProvider.notifier)
          .setActive(0, active: false);

      final menus = container.read(menuListProvider).value!;
      expect(menus[0].active, isFalse);
      expect(menus[1].active, isTrue);
    });

    test('add appends a menu locally (mock save, not yet backed by the API)',
        () async {
      final container = buildContainer(
        availability: {'product-1': true, 'product-2': true},
      );
      container.listen(menuListProvider, (_, _) {});
      await container.read(menuListProvider.future);

      container.read(menuListProvider.notifier).add(
            const MenuItemData(
              id: 'mock-1',
              name: 'Paket Komplit',
              price: 'Rp32.000',
            ),
          );

      final menus = container.read(menuListProvider).value!;
      expect(menus, hasLength(3));
      expect(menus.last.name, 'Paket Komplit');
    });
  });
}

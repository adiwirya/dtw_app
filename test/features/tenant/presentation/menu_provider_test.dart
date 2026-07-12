import 'package:dtw_app/features/tenant/presentation/providers/menu_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_item_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The shared flutter_test_config loads fonts in setUpAll, which needs the
  // binding; pure unit tests don't otherwise initialise it.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MenuList (mock notifier)', () {
    test('seeds the two menu-saya rows', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final menus = container.read(menuListProvider);
      expect(menus, hasLength(2));
      expect(menus.first.name, 'Paket Super Besar');
      expect(menus.last.name, 'Paket Hemat');
    });

    test('add appends a menu (Simpan Menu flow)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(menuListProvider.notifier).add(
            const MenuItemData(name: 'Paket Komplit', price: 'Rp32.000'),
          );

      final menus = container.read(menuListProvider);
      expect(menus, hasLength(3));
      expect(menus.last.name, 'Paket Komplit');
    });

    test('setActive flips the row active flag in place', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(menuListProvider.notifier).setActive(0, active: false);

      final menus = container.read(menuListProvider);
      expect(menus[0].active, isFalse);
      expect(menus[1].active, isTrue);
      expect(menus[0].name, 'Paket Super Besar');
    });
  });
}

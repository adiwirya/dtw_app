import 'package:dtw_app/features/tenant/presentation/widgets/menu_item_card.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'menu_provider.g.dart';

// TODO(open-question): the Menu data source and the menu-form field validation
// rules are unresolved (Open Questions 3/5/6 on this work item). Everything
// below is hard-coded, in-memory mock data harvested from the `menu-saya` /
// `tambah-menu` / `menu-diisi` tenant Figma references, and [MenuList.add] is a
// UI-only mock mutation. When the real source lands, replace this synchronous
// class-notifier with an async repository fetch
// (`Future<List<MenuItemData>>` backed by dio, per
// knowledge/riverpod-patterns.md) and have the Menu Saya screen consume the
// resulting AsyncValue; move the category/tag option lists behind that repo too.

/// Seed menus for the Menu Saya list (`menu-saya`: two cards).
const List<MenuItemData> _seedMenus = [
  MenuItemData(name: 'Paket Super Besar', price: 'Rp35.000'),
  MenuItemData(name: 'Paket Hemat', price: 'Rp29.000'),
];

/// The "Paket Komplit" row shown on `menu-berhasil-ditambahkan` (the list after
/// a successful add). Exposed so the screen can preview the just-added item on
/// that frame without a persisted backend.
const MenuItemData recentlyAddedMenu = MenuItemData(
  name: 'Paket Komplit',
  price: 'Rp32.000',
);

/// Mutable in-memory list of the tenant's menus (`menu-saya`).
///
/// UI-only: [add] appends a menu (the `Simpan Menu` flow) so navigating to
/// `menu-berhasil-ditambahkan` shows it. No persistence.
@riverpod
class MenuList extends _$MenuList {
  @override
  List<MenuItemData> build() => _seedMenus;

  /// Appends [item] to the list (mock save). Real save posts to the repository.
  void add(MenuItemData item) => state = [...state, item];

  /// Flips the active flag of the menu at [index] (the row toggle).
  void setActive(int index, {required bool active}) {
    state = [
      for (var i = 0; i < state.length; i++)
        if (i == index)
          MenuItemData(
            name: state[i].name,
            price: state[i].price,
            originalPrice: state[i].originalPrice,
            popular: state[i].popular,
            stockLabel: state[i].stockLabel,
            active: active,
            imageUrl: state[i].imageUrl,
          )
        else
          state[i],
    ];
  }
}

/// A pill filter on the Menu Saya list (`menu-saya` Frame 2011). Mock counts.
@immutable
class MenuFilter {
  const MenuFilter({required this.label, required this.count});

  /// Filter caption, e.g. `Semua`.
  final String label;

  /// Mock item count shown in parentheses, e.g. `120`.
  final int count;

  /// `Semua (120)` style rendering.
  String get display => '$label ($count)';
}

/// The Menu Saya filter tabs, in reference order (`menu-saya`). Mock data.
const List<MenuFilter> menuFilters = [
  MenuFilter(label: 'Semua', count: 120),
  MenuFilter(label: 'Aktif', count: 100),
  MenuFilter(label: 'Habis', count: 22),
  MenuFilter(label: 'Promo', count: 12),
  MenuFilter(label: 'Best Seller', count: 10),
];

/// Category options for the menu-form `Kategori` dropdown (`menu-diisi`).
const List<String> menuCategories = [
  'Nasi',
  'Ayam',
  'Minuman',
  'Snack',
  'Paket',
];

/// Tag options for the menu-form `Tag` field (`menu-diisi` → Chicken, Combo
/// Meal).
const List<String> menuTags = [
  'Chicken',
  'Combo Meal',
  'Spicy',
  'Best Seller',
];

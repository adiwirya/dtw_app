import 'package:dtw_app/features/tenant/data/repositories/product_repository.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_item_card.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'menu_provider.g.dart';

// TODO(open-question): the menu-form field validation rules and several
// `tambah-menu` fields (category, tags, discount, photo) are still
// unresolved/non-functional (Open Questions 3/5/6) — [MenuList.add] stays a
// UI-only mock append until that form is wired to `POST /v1/products`. The
// list itself and the active/inactive toggle are real, backed by
// `ProductRepository`.

/// The "Paket Komplit" row shown on `menu-berhasil-ditambahkan` (the list
/// after a successful add). Exposed so the screen can preview the just-added
/// item on that frame without a persisted backend.
const MenuItemData recentlyAddedMenu = MenuItemData(
  id: 'preview',
  name: 'Paket Komplit',
  price: 'Rp32.000',
);

/// The tenant's menu list (`menu-saya`), fetched from `GET /v1/products` with
/// per-branch availability (`GET /v1/tenant-branches/{id}/product-availability`)
/// merged in for the active/inactive toggle.
@riverpod
class MenuList extends _$MenuList {
  @override
  Future<List<MenuItemData>> build() async {
    final branch = await ref.watch(currentTenantBranchProvider.future);
    final repository = ref.watch(productRepositoryProvider);
    final products = await repository.fetchProducts(brandId: branch.brandId);

    // Best-effort: availability is a secondary fetch — if it fails, show the
    // menu as available rather than fail the whole list over a toggle state.
    Map<String, bool> availability;
    try {
      availability = await repository.fetchAvailability(branchId: branch.id);
    } on Object {
      availability = const {};
    }

    return [
      for (final product in products)
        product.toMenuItemData(isAvailable: availability[product.id] ?? true),
    ];
  }

  /// Appends [item] to the list (mock save — `tambah-menu` doesn't POST to
  /// the API yet, see the TODO above). Real save posts to the repository.
  void add(MenuItemData item) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([...current, item]);
  }

  /// Flips the branch-scoped availability of the menu at [index] (the row
  /// toggle), optimistically, reverting if the API call fails.
  Future<void> setActive(int index, {required bool active}) async {
    final current = state.value;
    if (current == null) {
      throw StateError(
        'MenuList: cannot set active — the list has not finished loading',
      );
    }
    if (index < 0 || index >= current.length) {
      throw StateError(
        'MenuList: cannot set active — index $index is out of range',
      );
    }
    final target = current[index];
    state = AsyncData([
      for (var i = 0; i < current.length; i++)
        if (i == index) target.copyWith(active: active) else current[i],
    ]);

    try {
      final branch = await ref.read(currentTenantBranchProvider.future);
      await ref.read(productRepositoryProvider).updateAvailability(
            target.id,
            branchId: branch.id,
            isAvailable: active,
          );
    } on Object catch (_) {
      state = AsyncData(current);
      rethrow;
    }
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

/// The Menu Saya filter tabs, in reference order (`menu-saya`). Mock data —
/// no API source for "Habis"/"Promo" concepts yet (see `docs/api-reference.md`).
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

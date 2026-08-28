import 'package:dtw_app/features/tenant/data/models/product_category.dart';
import 'package:dtw_app/features/tenant/data/repositories/product_repository.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_item_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'menu_provider.g.dart';

// TODO(open-question): the `tambah-menu` form's photo, tag and discount fields
// have no API support (Open Questions 3/5/6) and stay display-only. Name,
// category, price, description and the save itself are real.

/// The brand's product categories, for the add-menu form's `Kategori`
/// dropdown. Fetched once per session alongside the branch.
@riverpod
Future<List<ProductCategory>> productCategories(Ref ref) async {
  final branch = await ref.watch(currentTenantBranchProvider.future);
  return ref
      .watch(productRepositoryProvider)
      .fetchCategories(brandId: branch.brandId);
}

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

  /// Creates a product (`POST /v1/products`) and appends it to the list.
  ///
  /// Appends the created product rather than refetching: the response already
  /// carries every field the row renders, including the server-computed
  /// `total_price`. A brand-new product has no per-branch availability
  /// override yet, so it starts active.
  ///
  /// Returns the created product's id so the caller can attach variants to it
  /// (`ProductRepository.syncModifierGroups`).
  Future<String> create({
    required String name,
    required String categoryId,
    required int price,
    String? description,
  }) async {
    final branch = await ref.read(currentTenantBranchProvider.future);
    final product = await ref.read(productRepositoryProvider).createProduct(
          brandId: branch.brandId,
          categoryId: categoryId,
          name: name,
          price: price,
          description: description,
        );
    state = AsyncData([
      ...state.value ?? const <MenuItemData>[],
      product.toMenuItemData(),
    ]);
    return product.id;
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

/// A pill filter on the Menu Saya list (`menu-saya` Frame 2011).
@immutable
class MenuFilter {
  const MenuFilter({required this.label, required this.count});

  /// Filter caption, e.g. `Semua`.
  final String label;

  /// How many rows this pill matches.
  final int count;

  /// `Semua (12)` style rendering.
  String get display => '$label ($count)';
}

/// What the Menu Saya pills filter on.
///
/// The design frame offered five pills — Semua / Aktif / Habis / Promo / Best
/// Seller — with hardcoded counts and no filtering at all. Only the
/// active/inactive split has any backing data (`is_available` per branch);
/// "Habis", "Promo" and "Best Seller" are concepts the API does not have
/// anywhere (see `docs/api-reference.md`). Rather than keep three pills that
/// can only ever lie, the set is reduced to what the data actually supports —
/// consistent with how the Admin screen hides rows it has no source for.
enum MenuStatusFilter { semua, aktif, nonaktif }

/// The pills for [menus], with real counts derived from the list.
List<MenuFilter> menuFiltersFor(List<MenuItemData> menus) {
  final active = menus.where((m) => m.active).length;
  return [
    MenuFilter(label: 'Semua', count: menus.length),
    MenuFilter(label: 'Aktif', count: active),
    MenuFilter(label: 'Nonaktif', count: menus.length - active),
  ];
}

/// Whether [menu] belongs under [filter].
bool menuMatchesFilter(MenuItemData menu, MenuStatusFilter filter) =>
    switch (filter) {
      MenuStatusFilter.semua => true,
      MenuStatusFilter.aktif => menu.active,
      MenuStatusFilter.nonaktif => !menu.active,
    };

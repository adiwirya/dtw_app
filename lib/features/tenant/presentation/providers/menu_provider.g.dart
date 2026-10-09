// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The brand's product categories, for the add-menu form's `Kategori`
/// dropdown. Fetched once per session alongside the branch.

@ProviderFor(productCategories)
final productCategoriesProvider = ProductCategoriesProvider._();

/// The brand's product categories, for the add-menu form's `Kategori`
/// dropdown. Fetched once per session alongside the branch.

final class ProductCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductCategory>>,
          List<ProductCategory>,
          FutureOr<List<ProductCategory>>
        >
    with
        $FutureModifier<List<ProductCategory>>,
        $FutureProvider<List<ProductCategory>> {
  /// The brand's product categories, for the add-menu form's `Kategori`
  /// dropdown. Fetched once per session alongside the branch.
  ProductCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productCategoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productCategoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<ProductCategory>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProductCategory>> create(Ref ref) {
    return productCategories(ref);
  }
}

String _$productCategoriesHash() => r'c2e7d41dec525600d359bd91127125dbc621c8be';

/// The tenant's menu list (`menu-saya`), fetched from `GET /v1/products`.
/// The active/inactive toggle is the product's own `is_active` — the
/// per-branch availability endpoint documented in the spec (`GET/PATCH
/// /v1/tenant-branches/{id}/product-availability...`) does not exist live.

@ProviderFor(MenuList)
final menuListProvider = MenuListProvider._();

/// The tenant's menu list (`menu-saya`), fetched from `GET /v1/products`.
/// The active/inactive toggle is the product's own `is_active` — the
/// per-branch availability endpoint documented in the spec (`GET/PATCH
/// /v1/tenant-branches/{id}/product-availability...`) does not exist live.
final class MenuListProvider
    extends $AsyncNotifierProvider<MenuList, List<MenuItemData>> {
  /// The tenant's menu list (`menu-saya`), fetched from `GET /v1/products`.
  /// The active/inactive toggle is the product's own `is_active` — the
  /// per-branch availability endpoint documented in the spec (`GET/PATCH
  /// /v1/tenant-branches/{id}/product-availability...`) does not exist live.
  MenuListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menuListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menuListHash();

  @$internal
  @override
  MenuList create() => MenuList();
}

String _$menuListHash() => r'bc90670056bbec1bdad745eec2929a3f83fde7d4';

/// The tenant's menu list (`menu-saya`), fetched from `GET /v1/products`.
/// The active/inactive toggle is the product's own `is_active` — the
/// per-branch availability endpoint documented in the spec (`GET/PATCH
/// /v1/tenant-branches/{id}/product-availability...`) does not exist live.

abstract class _$MenuList extends $AsyncNotifier<List<MenuItemData>> {
  FutureOr<List<MenuItemData>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<MenuItemData>>, List<MenuItemData>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<MenuItemData>>, List<MenuItemData>>,
              AsyncValue<List<MenuItemData>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

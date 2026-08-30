// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$productCategoriesHash() => r'c2e7d41dec525600d359bd91127125dbc621c8be';

/// The brand's product categories, for the add-menu form's `Kategori`
/// dropdown. Fetched once per session alongside the branch.
///
/// Copied from [productCategories].
@ProviderFor(productCategories)
final productCategoriesProvider =
    AutoDisposeFutureProvider<List<ProductCategory>>.internal(
      productCategories,
      name: r'productCategoriesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$productCategoriesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProductCategoriesRef =
    AutoDisposeFutureProviderRef<List<ProductCategory>>;
String _$menuListHash() => r'e377bddf492bc127a418f7ec8904b76685a83a18';

/// The tenant's menu list (`menu-saya`), fetched from `GET /v1/products` with
/// per-branch availability (`GET /v1/tenant-branches/{id}/product-availability`)
/// merged in for the active/inactive toggle.
///
/// Copied from [MenuList].
@ProviderFor(MenuList)
final menuListProvider =
    AutoDisposeAsyncNotifierProvider<MenuList, List<MenuItemData>>.internal(
      MenuList.new,
      name: r'menuListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$menuListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MenuList = AutoDisposeAsyncNotifier<List<MenuItemData>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

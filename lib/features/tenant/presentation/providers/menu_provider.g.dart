// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$menuListHash() => r'40f7d006dcdb7b7d17ee6a52b374a5ad2360ac7f';

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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$menuListHash() => r'36a33854d3a978995d54b245784a001cc07f9386';

/// Mutable in-memory list of the tenant's menus (`menu-saya`).
///
/// UI-only: [add] appends a menu (the `Simpan Menu` flow) so navigating to
/// `menu-berhasil-ditambahkan` shows it. No persistence.
///
/// Copied from [MenuList].
@ProviderFor(MenuList)
final menuListProvider =
    AutoDisposeNotifierProvider<MenuList, List<MenuItemData>>.internal(
      MenuList.new,
      name: r'menuListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$menuListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MenuList = AutoDisposeNotifier<List<MenuItemData>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'variant_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$variantListHash() => r'b0e7d9cd8a955fcbc01e4f8f17d241fcf552763f';

/// The tenant's variant list (`kelola-varian` / `varian-disimpan`), fetched
/// from `GET /v1/modifier-groups`.
///
/// Copied from [VariantList].
@ProviderFor(VariantList)
final variantListProvider =
    AutoDisposeAsyncNotifierProvider<VariantList, List<VariantData>>.internal(
      VariantList.new,
      name: r'variantListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$variantListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$VariantList = AutoDisposeAsyncNotifier<List<VariantData>>;
String _$menuVariantSelectionHash() =>
    r'e9b59af2b6580fd6344a03d8cd90ea747d317370';

/// The variants picked on `PilihVarianScreen`, waiting to be attached to the
/// menu being created on `TambahMenuScreen`.
///
/// Cross-screen state, so it lives in a provider rather than travelling as
/// route `extra`: the picker is reached from the menu form through two
/// intermediate routes (`kelola-varian` → `tambah-varian`) and the selection
/// has to survive that round trip. `keepAlive` for the same reason — an
/// autoDisposing notifier would drop the selection the moment no screen is
/// watching it mid-navigation.
///
/// Cleared by `TambahMenuScreen` once the menu is saved, so the next
/// add-menu flow starts empty.
///
/// Copied from [MenuVariantSelection].
@ProviderFor(MenuVariantSelection)
final menuVariantSelectionProvider =
    NotifierProvider<MenuVariantSelection, List<VariantData>>.internal(
      MenuVariantSelection.new,
      name: r'menuVariantSelectionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$menuVariantSelectionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MenuVariantSelection = Notifier<List<VariantData>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

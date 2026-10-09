// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'variant_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The tenant's variant list (`kelola-varian` / `varian-disimpan`), fetched
/// from `GET /v1/modifier-groups`.

@ProviderFor(VariantList)
final variantListProvider = VariantListProvider._();

/// The tenant's variant list (`kelola-varian` / `varian-disimpan`), fetched
/// from `GET /v1/modifier-groups`.
final class VariantListProvider
    extends $AsyncNotifierProvider<VariantList, List<VariantData>> {
  /// The tenant's variant list (`kelola-varian` / `varian-disimpan`), fetched
  /// from `GET /v1/modifier-groups`.
  VariantListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'variantListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$variantListHash();

  @$internal
  @override
  VariantList create() => VariantList();
}

String _$variantListHash() => r'7c3965a38d1ce7a910d6c09cae7b05504047c33e';

/// The tenant's variant list (`kelola-varian` / `varian-disimpan`), fetched
/// from `GET /v1/modifier-groups`.

abstract class _$VariantList extends $AsyncNotifier<List<VariantData>> {
  FutureOr<List<VariantData>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<VariantData>>, List<VariantData>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<VariantData>>, List<VariantData>>,
              AsyncValue<List<VariantData>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

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

@ProviderFor(MenuVariantSelection)
final menuVariantSelectionProvider = MenuVariantSelectionProvider._();

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
final class MenuVariantSelectionProvider
    extends $NotifierProvider<MenuVariantSelection, List<VariantData>> {
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
  MenuVariantSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menuVariantSelectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menuVariantSelectionHash();

  @$internal
  @override
  MenuVariantSelection create() => MenuVariantSelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<VariantData> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<VariantData>>(value),
    );
  }
}

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

abstract class _$MenuVariantSelection extends $Notifier<List<VariantData>> {
  List<VariantData> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<VariantData>, List<VariantData>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<VariantData>, List<VariantData>>,
              List<VariantData>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

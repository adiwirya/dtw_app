// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'variant_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$variantListHash() => r'432ee607df99f8a62351a6bfe6093098f46cf410';

/// Mutable in-memory variant list backing `kelola-varian` (the manage screen).
///
/// Starts EMPTY to match the empty `kelola-varian` frame. UI-only: [add]
/// appends a newly-created variant (the Tambah Varian flow) and [loadSaved]
/// seeds the `savedVariants` mock. No persistence.
///
/// Copied from [VariantList].
@ProviderFor(VariantList)
final variantListProvider =
    AutoDisposeNotifierProvider<VariantList, List<VariantData>>.internal(
      VariantList.new,
      name: r'variantListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$variantListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$VariantList = AutoDisposeNotifier<List<VariantData>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

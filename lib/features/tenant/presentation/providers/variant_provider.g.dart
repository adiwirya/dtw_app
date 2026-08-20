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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'akun_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$busboyRatingHash() => r'e336637bd7b603d96dde92c82b1b9d81e71334de';

/// The logged-in busboy's average customer rating (`GET
/// /v1/busboys/{user}/rating`), already formatted (e.g. `'4.8'`) — or null
/// when there's no session user id yet, no ratings exist, or the fetch
/// failed. A display nicety, not core profile data, so this never surfaces
/// an error — [akunAccount] just falls back to `-` when this is null.
///
/// Copied from [busboyRating].
@ProviderFor(busboyRating)
final busboyRatingProvider = AutoDisposeFutureProvider<String?>.internal(
  busboyRating,
  name: r'busboyRatingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$busboyRatingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BusboyRatingRef = AutoDisposeFutureProviderRef<String?>;
String _$akunAccountHash() => r'e4abd1cba15e58e4dabc99418a83c9e2300ca488';

/// Backing data for the `akun` account screen.
///
/// Copied from [akunAccount].
@ProviderFor(akunAccount)
final akunAccountProvider = AutoDisposeProvider<AkunAccount>.internal(
  akunAccount,
  name: r'akunAccountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$akunAccountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AkunAccountRef = AutoDisposeProviderRef<AkunAccount>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'akun_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The logged-in busboy's average customer rating (`GET
/// /v1/busboys/{user}/rating`), already formatted (e.g. `'4.8'`) — or null
/// when there's no session user id yet, no ratings exist, or the fetch
/// failed. A display nicety, not core profile data, so this never surfaces
/// an error — [akunAccount] just falls back to `-` when this is null.

@ProviderFor(busboyRating)
final busboyRatingProvider = BusboyRatingProvider._();

/// The logged-in busboy's average customer rating (`GET
/// /v1/busboys/{user}/rating`), already formatted (e.g. `'4.8'`) — or null
/// when there's no session user id yet, no ratings exist, or the fetch
/// failed. A display nicety, not core profile data, so this never surfaces
/// an error — [akunAccount] just falls back to `-` when this is null.

final class BusboyRatingProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// The logged-in busboy's average customer rating (`GET
  /// /v1/busboys/{user}/rating`), already formatted (e.g. `'4.8'`) — or null
  /// when there's no session user id yet, no ratings exist, or the fetch
  /// failed. A display nicety, not core profile data, so this never surfaces
  /// an error — [akunAccount] just falls back to `-` when this is null.
  BusboyRatingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'busboyRatingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$busboyRatingHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return busboyRating(ref);
  }
}

String _$busboyRatingHash() => r'e336637bd7b603d96dde92c82b1b9d81e71334de';

/// Backing data for the `akun` account screen.

@ProviderFor(akunAccount)
final akunAccountProvider = AkunAccountProvider._();

/// Backing data for the `akun` account screen.

final class AkunAccountProvider
    extends $FunctionalProvider<AkunAccount, AkunAccount, AkunAccount>
    with $Provider<AkunAccount> {
  /// Backing data for the `akun` account screen.
  AkunAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'akunAccountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$akunAccountHash();

  @$internal
  @override
  $ProviderElement<AkunAccount> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AkunAccount create(Ref ref) {
    return akunAccount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AkunAccount value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AkunAccount>(value),
    );
  }
}

String _$akunAccountHash() => r'e3202c6abc2800955b9904ed44fa2b8e9cfceb85';

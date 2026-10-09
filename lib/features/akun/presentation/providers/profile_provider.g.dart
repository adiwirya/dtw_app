// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Backing data for the `profile-saya` screen.

@ProviderFor(busboyProfile)
final busboyProfileProvider = BusboyProfileProvider._();

/// Backing data for the `profile-saya` screen.

final class BusboyProfileProvider
    extends $FunctionalProvider<BusboyProfile, BusboyProfile, BusboyProfile>
    with $Provider<BusboyProfile> {
  /// Backing data for the `profile-saya` screen.
  BusboyProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'busboyProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$busboyProfileHash();

  @$internal
  @override
  $ProviderElement<BusboyProfile> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BusboyProfile create(Ref ref) {
    return busboyProfile(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BusboyProfile value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BusboyProfile>(value),
    );
  }
}

String _$busboyProfileHash() => r'b1b8bc1905cb7c1e24b60f3d83141dd6a33030ca';

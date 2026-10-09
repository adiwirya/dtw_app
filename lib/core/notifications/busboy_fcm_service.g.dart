// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'busboy_fcm_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(busboyFcmService)
final busboyFcmServiceProvider = BusboyFcmServiceProvider._();

final class BusboyFcmServiceProvider
    extends
        $FunctionalProvider<
          BusboyFcmService,
          BusboyFcmService,
          BusboyFcmService
        >
    with $Provider<BusboyFcmService> {
  BusboyFcmServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'busboyFcmServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$busboyFcmServiceHash();

  @$internal
  @override
  $ProviderElement<BusboyFcmService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BusboyFcmService create(Ref ref) {
    return busboyFcmService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BusboyFcmService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BusboyFcmService>(value),
    );
  }
}

String _$busboyFcmServiceHash() => r'66d95a8e8bdaad3ce794856bf1d9d6d2f3b56c2e';

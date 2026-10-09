// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'busboy_realtime_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(busboyRealtimeService)
final busboyRealtimeServiceProvider = BusboyRealtimeServiceProvider._();

final class BusboyRealtimeServiceProvider
    extends
        $FunctionalProvider<
          BusboyRealtimeService,
          BusboyRealtimeService,
          BusboyRealtimeService
        >
    with $Provider<BusboyRealtimeService> {
  BusboyRealtimeServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'busboyRealtimeServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$busboyRealtimeServiceHash();

  @$internal
  @override
  $ProviderElement<BusboyRealtimeService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BusboyRealtimeService create(Ref ref) {
    return busboyRealtimeService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BusboyRealtimeService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BusboyRealtimeService>(value),
    );
  }
}

String _$busboyRealtimeServiceHash() =>
    r'19384b5382f0388127651736d4d1222df4fc7756';

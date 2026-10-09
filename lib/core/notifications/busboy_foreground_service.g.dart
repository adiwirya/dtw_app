// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'busboy_foreground_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(busboyForegroundService)
final busboyForegroundServiceProvider = BusboyForegroundServiceProvider._();

final class BusboyForegroundServiceProvider
    extends
        $FunctionalProvider<
          BusboyForegroundService,
          BusboyForegroundService,
          BusboyForegroundService
        >
    with $Provider<BusboyForegroundService> {
  BusboyForegroundServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'busboyForegroundServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$busboyForegroundServiceHash();

  @$internal
  @override
  $ProviderElement<BusboyForegroundService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BusboyForegroundService create(Ref ref) {
    return busboyForegroundService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BusboyForegroundService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BusboyForegroundService>(value),
    );
  }
}

String _$busboyForegroundServiceHash() =>
    r'063cbd6789bb93abfedd3098b7f20164d5e85463';

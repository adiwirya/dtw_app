// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_realtime_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tenantRealtimeService)
final tenantRealtimeServiceProvider = TenantRealtimeServiceProvider._();

final class TenantRealtimeServiceProvider
    extends
        $FunctionalProvider<
          TenantRealtimeService,
          TenantRealtimeService,
          TenantRealtimeService
        >
    with $Provider<TenantRealtimeService> {
  TenantRealtimeServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tenantRealtimeServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tenantRealtimeServiceHash();

  @$internal
  @override
  $ProviderElement<TenantRealtimeService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TenantRealtimeService create(Ref ref) {
    return tenantRealtimeService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TenantRealtimeService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TenantRealtimeService>(value),
    );
  }
}

String _$tenantRealtimeServiceHash() =>
    r'c6578c04569ed04b3354064994475edec43d4a4c';

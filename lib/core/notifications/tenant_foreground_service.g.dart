// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_foreground_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tenantForegroundService)
final tenantForegroundServiceProvider = TenantForegroundServiceProvider._();

final class TenantForegroundServiceProvider
    extends
        $FunctionalProvider<
          TenantForegroundService,
          TenantForegroundService,
          TenantForegroundService
        >
    with $Provider<TenantForegroundService> {
  TenantForegroundServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tenantForegroundServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tenantForegroundServiceHash();

  @$internal
  @override
  $ProviderElement<TenantForegroundService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TenantForegroundService create(Ref ref) {
    return tenantForegroundService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TenantForegroundService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TenantForegroundService>(value),
    );
  }
}

String _$tenantForegroundServiceHash() =>
    r'9d24bdd4a9ede003abd2369b1ab08630c5da832f';

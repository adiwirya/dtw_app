// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_order_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tenantOrderRepository)
final tenantOrderRepositoryProvider = TenantOrderRepositoryProvider._();

final class TenantOrderRepositoryProvider
    extends
        $FunctionalProvider<
          TenantOrderRepository,
          TenantOrderRepository,
          TenantOrderRepository
        >
    with $Provider<TenantOrderRepository> {
  TenantOrderRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tenantOrderRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tenantOrderRepositoryHash();

  @$internal
  @override
  $ProviderElement<TenantOrderRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TenantOrderRepository create(Ref ref) {
    return tenantOrderRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TenantOrderRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TenantOrderRepository>(value),
    );
  }
}

String _$tenantOrderRepositoryHash() =>
    r'3e60b9e49cc345f175ea42e55818293775d4267f';

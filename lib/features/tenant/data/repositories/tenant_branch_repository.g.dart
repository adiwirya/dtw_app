// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_branch_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tenantBranchRepository)
final tenantBranchRepositoryProvider = TenantBranchRepositoryProvider._();

final class TenantBranchRepositoryProvider
    extends
        $FunctionalProvider<
          TenantBranchRepository,
          TenantBranchRepository,
          TenantBranchRepository
        >
    with $Provider<TenantBranchRepository> {
  TenantBranchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tenantBranchRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tenantBranchRepositoryHash();

  @$internal
  @override
  $ProviderElement<TenantBranchRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TenantBranchRepository create(Ref ref) {
    return tenantBranchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TenantBranchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TenantBranchRepository>(value),
    );
  }
}

String _$tenantBranchRepositoryHash() =>
    r'c380b172956615554f85bd2bcbdff0f7c1e56ea1';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_branch_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The current session's tenant branch (`GET /v1/tenant-branches/{id}`) — the
/// shared source every brand-scoped tenant screen (Menu, Varian, Admin
/// profile) resolves `branchId`/`brandId` through, so the branch is fetched
/// once per session instead of once per screen.

@ProviderFor(currentTenantBranch)
final currentTenantBranchProvider = CurrentTenantBranchProvider._();

/// The current session's tenant branch (`GET /v1/tenant-branches/{id}`) — the
/// shared source every brand-scoped tenant screen (Menu, Varian, Admin
/// profile) resolves `branchId`/`brandId` through, so the branch is fetched
/// once per session instead of once per screen.

final class CurrentTenantBranchProvider
    extends
        $FunctionalProvider<
          AsyncValue<TenantBranch>,
          TenantBranch,
          FutureOr<TenantBranch>
        >
    with $FutureModifier<TenantBranch>, $FutureProvider<TenantBranch> {
  /// The current session's tenant branch (`GET /v1/tenant-branches/{id}`) — the
  /// shared source every brand-scoped tenant screen (Menu, Varian, Admin
  /// profile) resolves `branchId`/`brandId` through, so the branch is fetched
  /// once per session instead of once per screen.
  CurrentTenantBranchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentTenantBranchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentTenantBranchHash();

  @$internal
  @override
  $FutureProviderElement<TenantBranch> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TenantBranch> create(Ref ref) {
    return currentTenantBranch(ref);
  }
}

String _$currentTenantBranchHash() =>
    r'b2d44b39b39c8640ca3ffde7b22c2e308fe5ba6d';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_branch_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentTenantBranchHash() =>
    r'b2d44b39b39c8640ca3ffde7b22c2e308fe5ba6d';

/// The current session's tenant branch (`GET /v1/tenant-branches/{id}`) — the
/// shared source every brand-scoped tenant screen (Menu, Varian, Admin
/// profile) resolves `branchId`/`brandId` through, so the branch is fetched
/// once per session instead of once per screen.
///
/// Copied from [currentTenantBranch].
@ProviderFor(currentTenantBranch)
final currentTenantBranchProvider =
    AutoDisposeFutureProvider<TenantBranch>.internal(
      currentTenantBranch,
      name: r'currentTenantBranchProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentTenantBranchHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentTenantBranchRef = AutoDisposeFutureProviderRef<TenantBranch>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

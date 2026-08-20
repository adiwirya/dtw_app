import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_branch.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_branch_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tenant_branch_provider.g.dart';

/// The current session's tenant branch (`GET /v1/tenant-branches/{id}`) — the
/// shared source every brand-scoped tenant screen (Menu, Varian, Admin
/// profile) resolves `branchId`/`brandId` through, so the branch is fetched
/// once per session instead of once per screen.
@riverpod
Future<TenantBranch> currentTenantBranch(Ref ref) async {
  final branchId =
      await ref.watch(localStorageProvider).read(tenantBranchIdStorageKey);
  if (branchId == null) {
    throw StateError('currentTenantBranch requires a tenant-scoped session');
  }
  return ref
      .watch(tenantBranchRepositoryProvider)
      .fetchBranch(branchId: branchId);
}

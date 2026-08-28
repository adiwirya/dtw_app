import 'package:dtw_app/features/tenant/data/models/tenant_admin_info.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_branch_repository.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'admin_status_provider.g.dart';

/// Real tenant identity for the Admin status screen, fetched from
/// `GET /v1/tenant-branches/{id}`. See [TenantAdminInfo] for which fields the
/// endpoint doesn't cover yet.
@riverpod
Future<TenantAdminInfo> tenantAdminInfo(Ref ref) async {
  final branch = await ref.watch(currentTenantBranchProvider.future);
  final repository = ref.watch(tenantBranchRepositoryProvider);

  // Best-effort: the round brand logo is a display nicety, not core profile
  // data, so a failed fetch degrades to no logo rather than failing the
  // whole screen.
  String? logoUrl;
  try {
    logoUrl = await repository.fetchBrandLogoUrl(brandId: branch.brandId);
  } on Object {
    logoUrl = null;
  }

  return branch.toTenantAdminInfo(brandLogoUrl: logoUrl);
}

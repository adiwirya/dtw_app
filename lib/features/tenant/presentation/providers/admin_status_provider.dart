import 'package:dtw_app/features/tenant/data/models/tenant_admin_info.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_branch_repository.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'admin_status_provider.g.dart';

// TODO(open-question): the online/offline flag itself is still unresolved
// (Open Questions 5/6 — what it actually gates and where it's persisted), so
// [AdminOnlineStatus] stays a UI-only, in-memory toggle for now.
// [tenantAdminInfo] below is no longer mocked — it fetches the real tenant
// branch identity.

/// Mutable online/offline flag for the Admin status screen.
///
/// One screen drives both `admin-offline` and `admin-online`: toggling flips
/// this flag in place (no navigation) and the screen rebuilds into the other
/// state. The two routes are entry points, keyed by [initialOnline] so a
/// deep-link to `/admin/online` lands online while `/admin` lands offline.
@riverpod
class AdminOnlineStatus extends _$AdminOnlineStatus {
  @override
  bool build({bool initialOnline = false}) => initialOnline;

  /// Sets the online flag to [value] (the requested state from the toggle).
  // ignore: use_setters_to_change_properties
  void set({required bool value}) => state = value;
}

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

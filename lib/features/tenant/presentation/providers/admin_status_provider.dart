import 'package:dtw_app/features/tenant/data/models/tenant_admin_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'admin_status_provider.g.dart';

// TODO(open-question): the store-status data source is unresolved (Open
// Questions 5/6 — what online/offline actually gates and where the flag lives).
// Until then this is a UI-only, in-memory toggle: [AdminOnlineStatus] holds the
// online flag and [tenantAdminInfo] returns hard-coded mock data harvested from
// the `admin-offline` / `admin-online` Figma references. When the real source
// lands, replace [AdminOnlineStatus] with an AsyncNotifier backed by a
// repository (persist the flag) and swap [tenantAdminInfo] for an async fetch.

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

/// Mock tenant identity + operational data for the Admin status screen.
@riverpod
TenantAdminInfo tenantAdminInfo(Ref ref) {
  return const TenantAdminInfo(
    name: 'KFC Fried Chicken',
    booth: 'Booth B1',
    brandLogoAsset: 'assets/images/brand-kfc.png',
    heroRating: '4.8',
    joinedLabel: '24 April 2024',
    rating: '4.3',
    contact: '+6282394627322',
    operationalHours: '10:00 - 22:00 WIB',
    operationalDays: 'Setiap Hari',
  );
}

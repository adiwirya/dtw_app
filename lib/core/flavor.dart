import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the user has completed login. The single merged `GoRouter` (see
/// `app_router.dart`) reads this to pick its `initialLocation`/`redirect`
/// (the login route once false, the signed-in home once true).
final isLoggedInProvider = StateProvider<bool>((ref) => false);

/// The `data.user.role` values the app routes on.
///
/// Confirmed with the backend team: `tenant_keeper` is a tenant-staff login and
/// `busboy` is a busboy login. Other values exist server-side but their shells
/// are undecided — `homePathFor` degrades to the scope-based decision for
/// anything it does not recognise.
abstract class AuthRoles {
  static const tenantKeeper = 'tenant_keeper';
  static const busboy = 'busboy';
}

/// The logged-in user's role, or null when unknown — set from
/// `LoginResponse.user.role` by `AuthController.login`, cleared on
/// logout/401.
///
/// This is what decides which shell a login lands on (see `homePathFor`).
final sessionRoleProvider = StateProvider<String?>((ref) => null);

/// The logged-in session's tenant branch id, or null for a non-tenant
/// (busboy) session — set from `LoginResponse.branchId` by
/// `AuthController.login`, cleared on logout/401.
///
/// Every branch-scoped call and channel keys off this
/// (`GET /v1/orders?branch_id=`, `private-branch.<id>`), so it is required
/// regardless of routing. It is also the fallback shell signal for a role
/// `homePathFor` does not recognise.
final sessionBranchIdProvider = StateProvider<String?>((ref) => null);

/// The logged-in user's username, or null when unknown — set from
/// `LoginResponse.user.username` by `AuthController.login`, cleared on
/// logout/401.
///
/// This is a login handle (e.g. `busboy1`), not a display name: the API has no
/// display-name field on `data.user`. Screens that greet the user show it
/// as-is rather than a fabricated full name, and omit the name entirely when
/// it is null.
final sessionUsernameProvider = StateProvider<String?>((ref) => null);

/// The logged-in session's busboy zone id, or null for a non-busboy
/// (tenant/no-scope) session — set from `LoginResponse.zoneId` by
/// `AuthController.login`, cleared on logout/401. Mirrors
/// [sessionBranchIdProvider] for the zone-scoped side of a session.
final sessionZoneIdProvider = StateProvider<String?>((ref) => null);

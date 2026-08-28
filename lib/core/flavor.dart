import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the user has completed login. The single merged `GoRouter` (see
/// `app_router.dart`) reads this to pick its `initialLocation`/`redirect`
/// (the login route once false, the signed-in home once true).
final isLoggedInProvider = StateProvider<bool>((ref) => false);

/// The logged-in session's tenant branch id, or null for a non-tenant
/// (busboy) session — set from `LoginResponse.branchId` by
/// `AuthController.login`, cleared on logout/401. The single merged
/// `GoRouter` reads this alongside [isLoggedInProvider] to decide which
/// shell ("/order" or "/tenant/order") a successful login lands on: there is
/// no separate "app flavor" concept, just this one piece of real login data.
final sessionBranchIdProvider = StateProvider<String?>((ref) => null);

/// The logged-in session's busboy zone id, or null for a non-busboy
/// (tenant/no-scope) session — set from `LoginResponse.zoneId` by
/// `AuthController.login`, cleared on logout/401. Mirrors
/// [sessionBranchIdProvider] for the zone-scoped side of a session.
final sessionZoneIdProvider = StateProvider<String?>((ref) => null);

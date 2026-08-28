import 'dart:async';

import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/realtime/busboy_realtime_service.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/features/auth/data/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_controller.g.dart';

/// State exposed by [AuthController] for the login/logout UI to render —
/// a plain synchronous state, not [AsyncValue], since login/logout are
/// fire-and-forget actions rather than a data fetch to cache/refresh.
class AuthState {
  const AuthState({this.isLoading = false, this.error});

  final bool isLoading;
  final Object? error;
}

/// `keepAlive: true` — without it this autoDisposes as soon as the last
/// reader drops its subscription (e.g. a bare `container.read`/`ref.read`
/// with no persistent `watch`), which would silently reset login/logout
/// state between the action and the next read.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AuthState build() => const AuthState();

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      final response = await ref.read(authRepositoryProvider).loginWithPassword(
            username: username,
            password: password,
          );
      ref.read(isLoggedInProvider.notifier).state = true;
      ref.read(sessionBranchIdProvider.notifier).state = response.branchId;
      ref.read(sessionZoneIdProvider.notifier).state = response.zoneId;
      state = const AuthState();

      // Reverb only drives live order-status updates on the tenant order
      // board — it is not part of the login contract, so a broken/slow
      // realtime endpoint must never gate or delay login success.
      // Fire-and-forget, errors swallowed: `TenantOrderBoard` tolerates
      // starting without a live socket (it still fetches its initial list
      // over the normal API) and picks up events once/if the socket comes up.
      final branchId = response.branchId;
      if (branchId != null) {
        unawaited(
          ref
              .read(tenantRealtimeServiceProvider)
              .connect(token: response.accessToken, branchId: branchId)
              .catchError((_) {}),
        );
      }
      // Same fire-and-forget contract for the busboy zone board.
      final zoneId = response.zoneId;
      if (zoneId != null) {
        unawaited(
          ref
              .read(busboyRealtimeServiceProvider)
              .connect(token: response.accessToken, zoneId: zoneId)
              .catchError((_) {}),
        );
      }
    } catch (error) {
      state = AuthState(error: error);
    }
  }

  Future<void> logout() async {
    // Disconnecting the realtime socket is best-effort cleanup, not a gate
    // on logout — a failure here must never strand the user in a logged-in
    // state.
    try {
      await ref.read(tenantRealtimeServiceProvider).disconnect();
    } on Object catch (_) {
      // Swallowed intentionally — see comment above.
    }
    try {
      await ref.read(busboyRealtimeServiceProvider).disconnect();
    } on Object catch (_) {
      // Swallowed intentionally — see comment above.
    }
    await ref.read(authRepositoryProvider).logout();
    ref.read(isLoggedInProvider.notifier).state = false;
    ref.read(sessionBranchIdProvider.notifier).state = null;
    ref.read(sessionZoneIdProvider.notifier).state = null;
  }
}

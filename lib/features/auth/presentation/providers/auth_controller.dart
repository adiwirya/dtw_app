import 'package:dtw_app/core/flavor.dart';
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
      // For a branch-scoped (tenant) login, `connect()` must succeed before
      // `isLoggedInProvider` flips — the router navigates away from the
      // login screen the instant that flag is true, so a connect failure
      // surfaced afterwards would render on a screen the user can no longer
      // see. Flipping the flags only once the socket is up keeps a failed
      // connect indistinguishable from a failed login: the user stays on
      // the login screen and sees the error.
      final branchId = response.branchId;
      if (branchId != null) {
        await ref.read(tenantRealtimeServiceProvider).connect(
              token: response.accessToken,
              branchId: branchId,
            );
      }
      ref.read(isLoggedInProvider.notifier).state = true;
      ref.read(appFlavorProvider.notifier).state =
          branchId != null ? AppFlavor.tenant : AppFlavor.busboy;
      state = const AuthState();
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
    await ref.read(authRepositoryProvider).logout();
    ref.read(isLoggedInProvider.notifier).state = false;
    // Logout must clear the flavor as well, mirroring the 401 interceptor in
    // `dioProvider`: `App` renders whichever router [appFlavorProvider]
    // names, so a tenant logout that left the flavor on tenant would land
    // back on `tenantRouter`'s `/login` rather than the real shared
    // `LoginScreen`.
    ref.read(appFlavorProvider.notifier).state = AppFlavor.busboy;
  }
}

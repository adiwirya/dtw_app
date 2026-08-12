import 'package:dtw_app/core/flavor.dart';
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
      ref.read(appFlavorProvider.notifier).state =
          response.branchId != null ? AppFlavor.tenant : AppFlavor.busboy;
      state = const AuthState();
    } catch (error) {
      state = AuthState(error: error);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.read(isLoggedInProvider.notifier).state = false;
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `keepAlive: true` — without it this autoDisposes as soon as the last
/// reader drops its subscription (e.g. a bare `container.read`/`ref.read`
/// with no persistent `watch`), which would silently reset login/logout
/// state between the action and the next read.

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// `keepAlive: true` — without it this autoDisposes as soon as the last
/// reader drops its subscription (e.g. a bare `container.read`/`ref.read`
/// with no persistent `watch`), which would silently reset login/logout
/// state between the action and the next read.
final class AuthControllerProvider
    extends $NotifierProvider<AuthController, AuthState> {
  /// `keepAlive: true` — without it this autoDisposes as soon as the last
  /// reader drops its subscription (e.g. a bare `container.read`/`ref.read`
  /// with no persistent `watch`), which would silently reset login/logout
  /// state between the action and the next read.
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthState>(value),
    );
  }
}

String _$authControllerHash() => r'41e190a8bb51310514dd4c56fc09c9c2e73d2a89';

/// `keepAlive: true` — without it this autoDisposes as soon as the last
/// reader drops its subscription (e.g. a bare `container.read`/`ref.read`
/// with no persistent `watch`), which would silently reset login/logout
/// state between the action and the next read.

abstract class _$AuthController extends $Notifier<AuthState> {
  AuthState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AuthState, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthState, AuthState>,
              AuthState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

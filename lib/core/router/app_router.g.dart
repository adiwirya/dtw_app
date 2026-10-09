// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The single `GoRouter` for the whole app — one login route, and the
/// busboy and tenant bottom-nav shells mounted side by side (busboy at
/// `/order` etc., tenant under `/tenant/...` — see `TenantRoutes`). There is
/// no "app flavor" concept and no router per flavor: which shell a login
/// lands on is [homePathFor] of the session's role.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// The single `GoRouter` for the whole app — one login route, and the
/// busboy and tenant bottom-nav shells mounted side by side (busboy at
/// `/order` etc., tenant under `/tenant/...` — see `TenantRoutes`). There is
/// no "app flavor" concept and no router per flavor: which shell a login
/// lands on is [homePathFor] of the session's role.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// The single `GoRouter` for the whole app — one login route, and the
  /// busboy and tenant bottom-nav shells mounted side by side (busboy at
  /// `/order` etc., tenant under `/tenant/...` — see `TenantRoutes`). There is
  /// no "app flavor" concept and no router per flavor: which shell a login
  /// lands on is [homePathFor] of the session's role.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'5274d3edbe457bd217b9df2f9a92e5e13be7d449';

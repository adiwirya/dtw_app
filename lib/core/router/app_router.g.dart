// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appRouterHash() => r'e913155dd6a2e8c3c4c246786be9e4493b6b24de';

/// The single `GoRouter` for the whole app — one login route, and the
/// busboy and tenant bottom-nav shells mounted side by side (busboy at
/// `/order` etc., tenant under `/tenant/...` — see `TenantRoutes`). There is
/// no "app flavor" concept: which shell a login lands on is decided purely
/// by [sessionBranchIdProvider] (set from the real login response), not by
/// a separate router per flavor.
///
/// Copied from [appRouter].
@ProviderFor(appRouter)
final appRouterProvider = AutoDisposeProvider<GoRouter>.internal(
  appRouter,
  name: r'appRouterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appRouterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppRouterRef = AutoDisposeProviderRef<GoRouter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

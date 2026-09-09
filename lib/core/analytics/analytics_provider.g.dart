// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firebaseAnalyticsHash() => r'9dc8ed2d3797e85f8c42fb3d2d96100467822e2a';

/// Null when no Firebase app has been initialized — `FirebaseAnalytics`
/// needs real platform channels no widget test loads, and `bootstrap()` is
/// the only call site that actually runs `Firebase.initializeApp` first, so
/// a test building `App()`/`appRouter` directly must still get a router.
///
/// Copied from [firebaseAnalytics].
@ProviderFor(firebaseAnalytics)
final firebaseAnalyticsProvider = Provider<FirebaseAnalytics?>.internal(
  firebaseAnalytics,
  name: r'firebaseAnalyticsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$firebaseAnalyticsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebaseAnalyticsRef = ProviderRef<FirebaseAnalytics?>;
String _$analyticsObserversHash() =>
    r'6a798374b250fab3fd2c7ece85df52fefbadb7ab';

/// GoRouter `observers:` list: logs an automatic `screen_view` event on
/// every route change (named after the matched route, falling back to the
/// route's path when unnamed) once Firebase is up — empty otherwise.
///
/// Copied from [analyticsObservers].
@ProviderFor(analyticsObservers)
final analyticsObserversProvider = Provider<List<NavigatorObserver>>.internal(
  analyticsObservers,
  name: r'analyticsObserversProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$analyticsObserversHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnalyticsObserversRef = ProviderRef<List<NavigatorObserver>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

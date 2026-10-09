// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Null when no Firebase app has been initialized — `FirebaseAnalytics`
/// needs real platform channels no widget test loads, and `bootstrap()` is
/// the only call site that actually runs `Firebase.initializeApp` first, so
/// a test building `App()`/`appRouter` directly must still get a router.

@ProviderFor(firebaseAnalytics)
final firebaseAnalyticsProvider = FirebaseAnalyticsProvider._();

/// Null when no Firebase app has been initialized — `FirebaseAnalytics`
/// needs real platform channels no widget test loads, and `bootstrap()` is
/// the only call site that actually runs `Firebase.initializeApp` first, so
/// a test building `App()`/`appRouter` directly must still get a router.

final class FirebaseAnalyticsProvider
    extends
        $FunctionalProvider<
          FirebaseAnalytics?,
          FirebaseAnalytics?,
          FirebaseAnalytics?
        >
    with $Provider<FirebaseAnalytics?> {
  /// Null when no Firebase app has been initialized — `FirebaseAnalytics`
  /// needs real platform channels no widget test loads, and `bootstrap()` is
  /// the only call site that actually runs `Firebase.initializeApp` first, so
  /// a test building `App()`/`appRouter` directly must still get a router.
  FirebaseAnalyticsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAnalyticsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAnalyticsHash();

  @$internal
  @override
  $ProviderElement<FirebaseAnalytics?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseAnalytics? create(Ref ref) {
    return firebaseAnalytics(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseAnalytics? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseAnalytics?>(value),
    );
  }
}

String _$firebaseAnalyticsHash() => r'9dc8ed2d3797e85f8c42fb3d2d96100467822e2a';

/// GoRouter `observers:` list: logs an automatic `screen_view` event on
/// every route change (named after the matched route, falling back to the
/// route's path when unnamed) once Firebase is up — empty otherwise.

@ProviderFor(analyticsObservers)
final analyticsObserversProvider = AnalyticsObserversProvider._();

/// GoRouter `observers:` list: logs an automatic `screen_view` event on
/// every route change (named after the matched route, falling back to the
/// route's path when unnamed) once Firebase is up — empty otherwise.

final class AnalyticsObserversProvider
    extends
        $FunctionalProvider<
          List<NavigatorObserver>,
          List<NavigatorObserver>,
          List<NavigatorObserver>
        >
    with $Provider<List<NavigatorObserver>> {
  /// GoRouter `observers:` list: logs an automatic `screen_view` event on
  /// every route change (named after the matched route, falling back to the
  /// route's path when unnamed) once Firebase is up — empty otherwise.
  AnalyticsObserversProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsObserversProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsObserversHash();

  @$internal
  @override
  $ProviderElement<List<NavigatorObserver>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<NavigatorObserver> create(Ref ref) {
    return analyticsObservers(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<NavigatorObserver> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<NavigatorObserver>>(value),
    );
  }
}

String _$analyticsObserversHash() =>
    r'6a798374b250fab3fd2c7ece85df52fefbadb7ab';

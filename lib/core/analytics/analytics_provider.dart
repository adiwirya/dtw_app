import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analytics_provider.g.dart';

/// Null when no Firebase app has been initialized — `FirebaseAnalytics`
/// needs real platform channels no widget test loads, and `bootstrap()` is
/// the only call site that actually runs `Firebase.initializeApp` first, so
/// a test building `App()`/`appRouter` directly must still get a router.
@Riverpod(keepAlive: true)
FirebaseAnalytics? firebaseAnalytics(Ref ref) =>
    Firebase.apps.isEmpty ? null : FirebaseAnalytics.instance;

/// GoRouter `observers:` list: logs an automatic `screen_view` event on
/// every route change (named after the matched route, falling back to the
/// route's path when unnamed) once Firebase is up — empty otherwise.
@Riverpod(keepAlive: true)
List<NavigatorObserver> analyticsObservers(Ref ref) {
  final analytics = ref.watch(firebaseAnalyticsProvider);
  if (analytics == null) return const [];
  return [FirebaseAnalyticsObserver(analytics: analytics)];
}

import 'package:dtw_app/core/analytics/analytics_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Firebase.apps is a static getter backed by real platform channels, so the
// "Firebase initialized" branch can't be exercised in a widget/unit test —
// only integration tests run against a real bootstrap() can reach it. This
// covers the branch every other test in this suite actually runs under:
// no Firebase app registered.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('firebaseAnalyticsProvider is null when no Firebase app is up', () {
    expect(Firebase.apps, isEmpty);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(firebaseAnalyticsProvider), isNull);
  });

  test('analyticsObservers is empty when no Firebase app is up', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(analyticsObserversProvider), isEmpty);
  });
}

import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/device/data/repositories/device_repository.dart';
import 'package:dtw_app/features/device/data/services/device_identity.dart';
import 'package:dtw_app/features/device/presentation/screens/device_onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/canned_dio.dart';
import '../../../../support/fake_device_identity.dart';
import '../../../../support/fake_local_storage.dart';

Map<String, dynamic> _envelope(int code) => {
  'meta': {
    'success': code < 300,
    'message': code < 300 ? 'Success' : 'Error',
    'code': code,
    'trace_id': 'abc',
  },
  'data': code < 300 ? {'id': 'dev-1'} : null,
};

ProviderContainer _container({
  required DeviceIdentity identity,
  required int statusCode,
  FakeLocalStorage? storage,
}) {
  return ProviderContainer(
    overrides: [
      localStorageProvider.overrideWithValue(storage ?? FakeLocalStorage()),
      deviceIdentityProvider.overrideWithValue(identity),
      deviceRepositoryProvider.overrideWithValue(
        DeviceRepository(dio: cannedDio(statusCode, _envelope(statusCode))),
      ),
      // deviceRegisteredProvider defaults `true` (so unrelated tests that
      // don't override it aren't forced through onboarding) — this screen's
      // own tests care about the false->true transition, so they need the
      // real pre-onboarding-success starting state made explicit.
      deviceRegisteredProvider.overrideWith((ref) => false),
    ],
  );
}

void main() {
  testWidgets('shows the preparing-device message on first frame', (
    tester,
  ) async {
    final container = _container(
      identity: FakeDeviceIdentity(deviceId: 'dev-1', fcmToken: 'tok-1'),
      statusCode: 201,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DeviceOnboardingScreen()),
      ),
    );

    // `initState` sets loading state synchronously before its first
    // `await`, so `pumpWidget`'s own first frame already reflects it —
    // asserting here (before any further pump lets the async register call
    // resolve) is what makes this deterministic.
    expect(find.text('Menyiapkan Device'), findsOneWidget);

    // Drain the in-flight register() call before the test ends — Dio's
    // request pipeline schedules an internal zero-duration Timer, and
    // Flutter's test binding fails the test if a Timer is still pending
    // when the widget tree is torn down, even one that doesn't affect this
    // test's own assertion above.
    await tester.pumpAndSettle();
  });

  testWidgets(
    'on success, persists the registered flag and flips the provider',
    (tester) async {
      final storage = FakeLocalStorage();
      final container = _container(
        identity: FakeDeviceIdentity(deviceId: 'dev-1', fcmToken: 'tok-1'),
        statusCode: 201,
        storage: storage,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DeviceOnboardingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(deviceRegisteredProvider), isTrue);
      expect(storage.values[deviceRegisteredStorageKey], 'true');
    },
  );

  testWidgets('on failure, shows the error and a Coba Lagi retry', (
    tester,
  ) async {
    final container = _container(
      identity: FakeDeviceIdentity(deviceId: 'dev-1', fcmToken: 'tok-1'),
      statusCode: 500,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DeviceOnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gagal Menyiapkan Device'), findsOneWidget);
    expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
    expect(container.read(deviceRegisteredProvider), isFalse);
  });

  testWidgets(
    'a null deviceId/fcmToken shows the error UI without calling the API',
    (tester) async {
      final container = _container(
        identity: FakeDeviceIdentity(), // both null
        statusCode: 201, // would succeed if ever called
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DeviceOnboardingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gagal Menyiapkan Device'), findsOneWidget);
      expect(container.read(deviceRegisteredProvider), isFalse);
    },
  );

  testWidgets('tapping Coba Lagi re-runs registration', (tester) async {
    final container = _container(
      identity: FakeDeviceIdentity(deviceId: 'dev-1', fcmToken: 'tok-1'),
      statusCode: 500,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DeviceOnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Coba Lagi'), findsOneWidget);

    await tester.tap(find.text('Coba Lagi'));
    await tester.pump();

    expect(find.text('Menyiapkan Device'), findsOneWidget);

    // Same as the first test — drain the retry's in-flight register() call
    // before the test ends so no Dio-internal Timer leaks past teardown.
    await tester.pumpAndSettle();
  });
}

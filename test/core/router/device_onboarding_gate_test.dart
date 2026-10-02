import 'package:dtw_app/app.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/features/device/data/services/device_identity.dart';
import 'package:dtw_app/features/device/presentation/screens/device_onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/busboy_board.dart';
import '../../support/fake_device_identity.dart';

Future<void> _pumpApp(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the device-onboarding gate wins over the logged-in redirect',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          ...busboyBoardOverrides(dio: cannedDeliveryListDio([])),
          deviceRegisteredProvider.overrideWith((ref) => false),
          // Null identity -> the screen fails fast locally, with no real
          // network/platform call, and never flips the gate back to true.
          deviceIdentityProvider.overrideWithValue(FakeDeviceIdentity()),
        ],
      );
      addTearDown(container.dispose);
      container.read(isLoggedInProvider.notifier).state = true;

      await _pumpApp(tester, container);

      expect(find.byType(DeviceOnboardingScreen), findsOneWidget);
      expect(find.text('Ambil'), findsNothing);
    },
  );

  // Regression: a fresh install (device unregistered AND never logged in)
  // used to bounce /onboarding -> /login -> /onboarding forever, because the
  // redirect callback fell through to the login guard even while still on
  // /onboarding with an unregistered device — go_router's redirect-loop
  // detector threw a GoException before the app ever rendered anything.
  testWidgets(
    'a fresh install (unregistered device, never logged in) stays on '
    'onboarding without looping',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          ...busboyBoardOverrides(dio: cannedDeliveryListDio([])),
          deviceRegisteredProvider.overrideWith((ref) => false),
          deviceIdentityProvider.overrideWithValue(FakeDeviceIdentity()),
        ],
      );
      addTearDown(container.dispose);
      // Deliberately NOT setting isLoggedInProvider — a fresh install has
      // never logged in.

      await _pumpApp(tester, container);

      expect(find.byType(DeviceOnboardingScreen), findsOneWidget);
      expect(find.text('Username'), findsNothing);
    },
  );

  testWidgets(
    'once the device is registered, a logged-in session lands on its shell',
    (tester) async {
      final container = ProviderContainer(
        overrides: busboyBoardOverrides(dio: cannedDeliveryListDio([])),
      );
      addTearDown(container.dispose);
      container.read(isLoggedInProvider.notifier).state = true;

      await _pumpApp(tester, container);

      expect(find.text('Ambil'), findsOneWidget);
      expect(find.byType(DeviceOnboardingScreen), findsNothing);
    },
  );
}

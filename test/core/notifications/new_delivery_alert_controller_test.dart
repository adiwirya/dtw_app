import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/notifications/new_delivery_alert_controller.dart';
import 'package:dtw_app/core/notifications/new_order_alert_controller.dart';
import 'package:dtw_app/core/notifications/new_order_alerts.dart';
import 'package:dtw_app/core/realtime/busboy_realtime_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/busboy_board.dart';
import '../../support/fake_busboy_realtime_service.dart';
import '../../support/fake_new_order_alerts.dart';

/// Builds a container wired to fakes, with the lifecycle pinned to [state].
({
  ProviderContainer container,
  FakeBusboyRealtimeService realtime,
  FakeNewOrderAlerts alerts,
})
_harness({
  AppLifecycleState? state = AppLifecycleState.resumed,
  bool loggedIn = true,
  String? role = AuthRoles.busboy,
  String? branchId,
}) {
  final realtime = FakeBusboyRealtimeService();
  final alerts = FakeNewOrderAlerts();
  final container = ProviderContainer(
    overrides: [
      isLoggedInProvider.overrideWith((ref) => loggedIn),
      sessionRoleProvider.overrideWith((ref) => role),
      sessionBranchIdProvider.overrideWith((ref) => branchId),
      busboyRealtimeServiceProvider.overrideWithValue(realtime),
      busboyNewOrderAlertsProvider.overrideWithValue(alerts),
      appLifecycleProvider.overrideWithValue(() => state),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(realtime.close);
  return (container: container, realtime: realtime, alerts: alerts);
}

Map<String, dynamic> _payload({String id = 'delivery-1'}) => deliveryJson(
  id: id,
  status: 'PENDING_PICKUP',
  orders: [
    deliveryOrderJson(
      orderId: 'order-1',
      items: [deliveryItemJson(productName: 'Es Kopi')],
    ),
  ],
);

/// Lets the stream listener run.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('sets up channels and permission before any delivery arrives',
      () async {
    final h = _harness();

    h.container.read(newDeliveryAlertProvider);
    await _settle();

    expect(h.alerts.initializeCallCount, 1);
  });

  group('while the app is on screen', () {
    test('chimes, without a tray notification', () async {
      final h = _harness();
      h.container.read(newDeliveryAlertProvider);

      h.realtime.emitDeliveryCreated(_payload());
      await _settle();

      expect(h.alerts.chimeCallCount, 1);
      expect(h.alerts.notified, isEmpty);
    });

    // The platform reports no lifecycle state until its first transition,
    // which on a cold start lands after frames are already running.
    test('treats an unreported lifecycle as on screen', () async {
      final h = _harness(state: null);
      h.container.read(newDeliveryAlertProvider);

      h.realtime.emitDeliveryCreated(_payload());
      await _settle();

      expect(h.alerts.chimeCallCount, 1);
      expect(h.alerts.notified, isEmpty);
    });
  });

  group('while the app is backgrounded', () {
    test('posts a notification and stays silent in-app', () async {
      final h = _harness(state: AppLifecycleState.paused);
      h.container.read(newDeliveryAlertProvider);

      h.realtime.emitDeliveryCreated(_payload());
      await _settle();

      expect(h.alerts.notified.single.body, 'Meja A12 · 1 item');
      expect(h.alerts.chimeCallCount, 0);
    });
  });

  test('a second delivery alerts again', () async {
    final h = _harness();
    h.container.read(newDeliveryAlertProvider);

    h.realtime.emitDeliveryCreated(_payload());
    await _settle();
    h.realtime.emitDeliveryCreated(_payload(id: 'delivery-2'));
    await _settle();

    expect(h.alerts.chimeCallCount, 2);
  });

  test('a redelivered event for the same delivery does not alert twice',
      () async {
    final h = _harness();
    h.container.read(newDeliveryAlertProvider);

    h.realtime.emitDeliveryCreated(_payload());
    await _settle();
    h.realtime.emitDeliveryCreated(_payload());
    await _settle();

    expect(h.alerts.chimeCallCount, 1);
  });

  group('alerting never takes the socket down with it', () {
    test('a chime failure still lets the next delivery alert', () async {
      final h = _harness()..alerts.chimeError = Exception('no audio device');
      h.container.read(newDeliveryAlertProvider);

      h.realtime.emitDeliveryCreated(_payload());
      await _settle();
      h.realtime.emitDeliveryCreated(_payload(id: 'delivery-2'));
      await _settle();

      expect(h.alerts.chimeCallCount, 2);
    });

    test('a failed initialize still leaves the listener wired', () async {
      final h = _harness()..alerts.initializeError = Exception('no channel');
      h.container.read(newDeliveryAlertProvider);
      await _settle();

      h.realtime.emitDeliveryCreated(_payload());
      await _settle();

      expect(h.alerts.chimeCallCount, 1);
    });

    test('an unparseable payload is skipped, not thrown', () async {
      final h = _harness();
      h.container.read(newDeliveryAlertProvider);

      h.realtime.emitDeliveryCreated({'nonsense': true});
      await _settle();
      expect(h.alerts.chimeCallCount, 0);

      // ...and the listener survives to announce the next real one.
      h.realtime.emitDeliveryCreated(_payload());
      await _settle();
      expect(h.alerts.chimeCallCount, 1);
    });
  });

  // A tenant session has no delivery board, so alerting it would ask for
  // notification permission at startup for something that can never fire.
  group('a non-busboy session is left alone', () {
    test('does not initialize the plugins or listen', () async {
      final h = _harness(role: AuthRoles.tenantKeeper, branchId: 'branch-1');

      h.container.read(newDeliveryAlertProvider);
      await _settle();
      h.realtime.emitDeliveryCreated(_payload());
      await _settle();

      expect(h.alerts.initializeCallCount, 0);
      expect(h.alerts.chimeCallCount, 0);
      expect(h.alerts.notified, isEmpty);
    });

    // `homePathFor(null, null)` — the pre-login shape — itself resolves to
    // the busboy path, so this needs its own `isLoggedInProvider` check
    // rather than relying on the role/branch fallback the way the tenant
    // equivalent test does.
    test('a signed-out session is left alone too', () async {
      final h = _harness(loggedIn: false, role: null);

      h.container.read(newDeliveryAlertProvider);
      await _settle();

      expect(h.alerts.initializeCallCount, 0);
    });
  });
}

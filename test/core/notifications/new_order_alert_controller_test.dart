import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/notifications/new_order_alert_controller.dart';
import 'package:dtw_app/core/notifications/new_order_alerts.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_order_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_new_order_alerts.dart';
import '../../support/fake_tenant_realtime_service.dart';
import '../../support/tenant_board.dart';

/// Answers `fetchMissedEvents` with [missed] (or throws [error]) without a
/// real Dio round trip — mirrors `tenant_order_provider_test.dart`'s
/// `_RecordingReplayRepository`. The gap-fill runs from a fire-and-forget
/// stream listener with no Future for a test to await, so keeping this
/// synchronous (beyond the one `async` hop) is what makes a single
/// `_settle()` enough to observe it. `NewOrderAlertBanner` never calls the
/// other methods, so they're left unimplemented.
class _StubReplayRepository implements TenantOrderRepository {
  _StubReplayRepository({this.missed = const [], this.error});

  final List<TenantOrder> missed;
  final Exception? error;

  @override
  Future<List<TenantOrder>> fetchMissedEvents({
    required String branchId,
    required int afterId,
  }) async {
    if (error case final e?) throw e;
    return missed;
  }

  @override
  Future<List<TenantOrder>> fetchOrders({required String branchId}) =>
      throw UnimplementedError();

  @override
  Future<void> updateStatus(
    String orderId, {
    required TenantOrderStatus status,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> processOrder(
    String orderId, {
    required List<String> rejectedItemIds,
  }) =>
      throw UnimplementedError();
}

/// Builds a container wired to fakes, with the lifecycle pinned to [state].
({
  ProviderContainer container,
  FakeTenantRealtimeService realtime,
  FakeNewOrderAlerts alerts,
})
_harness({
  AppLifecycleState? state = AppLifecycleState.resumed,
  String? role = AuthRoles.tenantKeeper,
  String? branchId = testBranchId,
  List<TenantOrder> missedEvents = const [],
  Exception? gapFillError,
}) {
  final realtime = FakeTenantRealtimeService();
  final alerts = FakeNewOrderAlerts();
  final container = ProviderContainer(
    overrides: [
      sessionRoleProvider.overrideWith((ref) => role),
      sessionBranchIdProvider.overrideWith((ref) => branchId),
      tenantRealtimeServiceProvider.overrideWithValue(realtime),
      newOrderAlertsProvider.overrideWithValue(alerts),
      appLifecycleProvider.overrideWithValue(() => state),
      tenantOrderRepositoryProvider.overrideWithValue(
        _StubReplayRepository(missed: missedEvents, error: gapFillError),
      ),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(realtime.close);
  return (container: container, realtime: realtime, alerts: alerts);
}

Map<String, dynamic> _payload({String id = 'order-1', int? broadcastEventId}) =>
    tenantOrderJson(
      id: id,
      status: 'PENDING',
      tableNumber: 'A-12',
      grandTotal: 45000,
      broadcastEventId: broadcastEventId,
    );

/// A [TenantOrder] as `fetchMissedEvents` would hand back — built off the
/// same flat JSON shape [_payload] uses.
TenantOrder _order({String id = 'order-1', int? broadcastEventId}) =>
    TenantOrder.fromJson(_payload(id: id, broadcastEventId: broadcastEventId));

/// Lets the stream listener run.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('sets up channels and permission before any order arrives', () async {
    final h = _harness();

    h.container.read(newOrderAlertBannerProvider);
    await _settle();

    // Asking for notification permission at the moment an order lands would
    // put a system dialog over the thing the tenant needs to act on.
    expect(h.alerts.initializeCallCount, 1);
  });

  group('while the app is on screen', () {
    test('chimes and raises the banner, without a tray notification', () async {
      final h = _harness();
      h.container.read(newOrderAlertBannerProvider);

      h.realtime.emitOrderCreated(_payload());
      await _settle();

      expect(h.alerts.chimeCallCount, 1);
      expect(
        h.container.read(newOrderAlertBannerProvider)?.body,
        'Meja A-12 · Rp45.000',
      );
      // Posting to the tray while the tenant is looking at the order screen
      // is clutter, and the channel sound would double up with the chime.
      expect(h.alerts.notified, isEmpty);
    });

    // The platform reports no lifecycle state until its first transition,
    // which on a cold start lands after frames are already running.
    test('treats an unreported lifecycle as on screen', () async {
      final h = _harness(state: null);
      h.container.read(newOrderAlertBannerProvider);

      h.realtime.emitOrderCreated(_payload());
      await _settle();

      expect(h.alerts.chimeCallCount, 1);
      expect(h.alerts.notified, isEmpty);
    });
  });

  group('while the app is backgrounded', () {
    test('posts a notification and stays silent in-app', () async {
      final h = _harness(state: AppLifecycleState.paused);
      h.container.read(newOrderAlertBannerProvider);

      h.realtime.emitOrderCreated(_payload());
      await _settle();

      expect(h.alerts.notified.single.body, 'Meja A-12 · Rp45.000');
      // The channel carries its own sound; chiming too would double up.
      expect(h.alerts.chimeCallCount, 0);
      // And no banner queued up to ambush the tenant on resume.
      expect(h.container.read(newOrderAlertBannerProvider), isNull);
    });

    test('inactive counts as backgrounded', () async {
      final h = _harness(state: AppLifecycleState.inactive);
      h.container.read(newOrderAlertBannerProvider);

      h.realtime.emitOrderCreated(_payload());
      await _settle();

      expect(h.alerts.notified, hasLength(1));
      expect(h.alerts.chimeCallCount, 0);
    });
  });

  test('the banner dismisses itself', () async {
    final h = _harness();
    h.container.read(newOrderAlertBannerProvider);

    h.realtime.emitOrderCreated(_payload());
    await _settle();
    expect(h.container.read(newOrderAlertBannerProvider), isNotNull);

    await Future<void>.delayed(
      NewOrderAlertBanner.visibleFor + const Duration(milliseconds: 50),
    );
    expect(h.container.read(newOrderAlertBannerProvider), isNull);
  });

  test('a second order replaces the first and restarts the timer', () async {
    final h = _harness();
    h.container.read(newOrderAlertBannerProvider);

    h.realtime.emitOrderCreated(_payload());
    await _settle();
    h.realtime.emitOrderCreated(_payload(id: 'order-2'));
    await _settle();

    expect(h.container.read(newOrderAlertBannerProvider)?.orderId, 'order-2');
    expect(h.alerts.chimeCallCount, 2);
  });

  group('alerting never takes the socket down with it', () {
    // These all run on a stream listener with nothing awaiting them, so an
    // escaping error surfaces as an uncaught async error rather than as
    // anything the tenant could act on — and the next order would still need
    // to get through.
    test('a chime failure still shows the banner, and the next order '
        'still alerts', () async {
      final h = _harness()..alerts.chimeError = Exception('no audio device');
      h.container.read(newOrderAlertBannerProvider);

      h.realtime.emitOrderCreated(_payload());
      await _settle();
      expect(h.container.read(newOrderAlertBannerProvider), isNotNull);

      h.realtime.emitOrderCreated(_payload(id: 'order-2'));
      await _settle();
      expect(h.container.read(newOrderAlertBannerProvider)?.orderId, 'order-2');
    });

    test(
      'a denied notification permission does not stop later orders',
      () async {
        final h = _harness(state: AppLifecycleState.paused)
          ..alerts.notifyError = Exception('permission denied');
        h.container.read(newOrderAlertBannerProvider);

        h.realtime.emitOrderCreated(_payload());
        await _settle();
        h.realtime.emitOrderCreated(_payload(id: 'order-2'));
        await _settle();

        expect(h.alerts.notified, hasLength(2));
      },
    );

    test('a failed initialize still leaves the listener wired', () async {
      final h = _harness()..alerts.initializeError = Exception('no channel');
      h.container.read(newOrderAlertBannerProvider);
      await _settle();

      h.realtime.emitOrderCreated(_payload());
      await _settle();

      expect(h.container.read(newOrderAlertBannerProvider), isNotNull);
    });

    test('an unparseable payload is skipped, not thrown', () async {
      final h = _harness();
      h.container.read(newOrderAlertBannerProvider);

      h.realtime.emitOrderCreated({'nonsense': true});
      await _settle();
      expect(h.container.read(newOrderAlertBannerProvider), isNull);

      // ...and the listener survives to announce the next real one.
      h.realtime.emitOrderCreated(_payload());
      await _settle();
      expect(h.container.read(newOrderAlertBannerProvider), isNotNull);
    });
  });

  // A busboy session has no tenant order board, so alerting it would ask for
  // notification permission at startup for something that can never fire.
  group('a non-tenant session is left alone', () {
    test('does not initialize the plugins or listen', () async {
      final h = _harness(role: AuthRoles.busboy, branchId: null);

      h.container.read(newOrderAlertBannerProvider);
      await _settle();
      h.realtime.emitOrderCreated(_payload());
      await _settle();

      expect(h.alerts.initializeCallCount, 0);
      expect(h.alerts.chimeCallCount, 0);
      expect(h.alerts.notified, isEmpty);
      expect(h.container.read(newOrderAlertBannerProvider), isNull);
    });

    test('a signed-out session is left alone too', () async {
      final h = _harness(role: null, branchId: null);

      h.container.read(newOrderAlertBannerProvider);
      await _settle();

      expect(h.alerts.initializeCallCount, 0);
    });

    // Same fallback the router uses: an unrecognised role with a branch scope
    // is treated as a tenant.
    test('an unknown role with a branch scope still alerts', () async {
      final h = _harness(role: 'something_new');

      h.container.read(newOrderAlertBannerProvider);
      h.realtime.emitOrderCreated(_payload());
      await _settle();

      expect(h.container.read(newOrderAlertBannerProvider), isNotNull);
    });
  });

  group('reconnect gap-fill', () {
    test('alerts an order that arrived while disconnected', () async {
      final h = _harness(missedEvents: [_order(id: 'order-2')]);
      h.container.read(newOrderAlertBannerProvider);

      // Seeds `_lastBroadcastEventId` — without a prior live order there is
      // no cursor to replay from (mirrors `TenantOrderBoard`'s own guard).
      h.realtime.emitOrderCreated(_payload(broadcastEventId: 1));
      await _settle();

      h.realtime.emitReconnected();
      await _settle();

      expect(h.alerts.chimeCallCount, 2);
      expect(h.container.read(newOrderAlertBannerProvider)?.orderId, 'order-2');
    });

    test('does not re-alert an order the live stream already delivered',
        () async {
      final h = _harness(missedEvents: [_order()]);
      h.container.read(newOrderAlertBannerProvider);

      h.realtime.emitOrderCreated(_payload(broadcastEventId: 1));
      await _settle();
      expect(h.alerts.chimeCallCount, 1);

      h.realtime.emitReconnected();
      await _settle();

      expect(h.alerts.chimeCallCount, 1);
    });

    test('a reconnect before any live order ever arrived is a no-op',
        () async {
      final h = _harness();
      h.container.read(newOrderAlertBannerProvider);

      h.realtime.emitReconnected();
      await _settle();

      expect(h.alerts.chimeCallCount, 0);
      expect(h.alerts.notified, isEmpty);
    });

    test('a gap-fill failure does not take the listener down with it',
        () async {
      final h = _harness(gapFillError: Exception('replay unreachable'));
      h.container.read(newOrderAlertBannerProvider);

      h.realtime.emitOrderCreated(_payload(broadcastEventId: 1));
      await _settle();
      h.realtime.emitReconnected();
      await _settle();

      h.realtime.emitOrderCreated(_payload(id: 'order-2'));
      await _settle();
      expect(h.container.read(newOrderAlertBannerProvider)?.orderId, 'order-2');
    });
  });

  test('dismiss clears the banner and is safe with nothing showing', () {
    final h = _harness();
    final notifier = h.container.read(newOrderAlertBannerProvider.notifier)
      ..dismiss();

    expect(h.container.read(newOrderAlertBannerProvider), isNull);
    notifier.dismiss();
    expect(h.container.read(newOrderAlertBannerProvider), isNull);
  });
}

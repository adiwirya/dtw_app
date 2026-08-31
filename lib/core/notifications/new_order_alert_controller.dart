import 'dart:async';

import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/notifications/new_order_alert.dart';
import 'package:dtw_app/core/notifications/new_order_alerts.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_order_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'new_order_alert_controller.g.dart';

/// Reads the app's current lifecycle state. Injected so a test can drive the
/// foreground/background branch without a real binding.
///
/// `SchedulerBinding.lifecycleState` is null until the platform reports the
/// first transition, which on a cold start is *after* frames are already
/// running — treated as foregrounded by [NewOrderAlertBanner], since that is
/// what it means.
@Riverpod(keepAlive: true)
AppLifecycleState? Function() appLifecycle(Ref ref) =>
    () => SchedulerBinding.instance.lifecycleState;

/// The alert currently shown as an in-app banner, or null for none.
///
/// Separate from firing the alert so the banner is pure UI state the widget
/// tree can watch, dismiss and re-show without reaching into plugins.
@Riverpod(keepAlive: true)
class NewOrderAlertBanner extends _$NewOrderAlertBanner {
  StreamSubscription<Map<String, dynamic>>? _subscription;
  StreamSubscription<void>? _reconnectedSubscription;
  Timer? _autoDismiss;

  /// How long the banner sits before dismissing itself. Long enough to read
  /// over a busy counter, short enough not to cover the order it announces.
  static const visibleFor = Duration(seconds: 6);

  /// Highest `broadcast_event_id` seen so far, for the reconnect gap-fill.
  /// Tracked independently of `TenantOrderBoard`'s own copy — this is a
  /// separate listener on the same stream, not a shared cursor.
  int? _lastBroadcastEventId;

  /// Order ids already alerted this session. The live stream and a
  /// reconnect gap-fill cover overlapping windows by design, so without
  /// this an order delivered both ways would chime/notify twice.
  final Set<String> _alertedOrderIds = {};

  @override
  NewOrderAlert? build() {
    // Only a tenant session has an order board to be alerted about. Gating on
    // the same [homePathFor] the router uses, rather than a second copy of
    // the role rules, is what keeps the two from drifting apart. Without this
    // a busboy would be asked for notification permission at startup for a
    // feature their session never fires.
    final isTenant =
        homePathFor(
          role: ref.watch(sessionRoleProvider),
          branchId: ref.watch(sessionBranchIdProvider),
        ) ==
        TenantRoutes.orderPath;
    if (!isTenant) return null;

    final alerts = ref.watch(newOrderAlertsProvider);
    final lifecycle = ref.watch(appLifecycleProvider);
    final realtime = ref.watch(tenantRealtimeServiceProvider);

    // Channels/permission are set up once, up front, rather than on the first
    // order — asking for notification permission at the moment an order lands
    // would put a system dialog over the thing the tenant needs to act on.
    unawaited(_guard(alerts.initialize, 'initialize'));

    _subscription = realtime.orderCreated.listen(
      (payload) => _announcePayload(payload, alerts, lifecycle),
    );

    // Mirrors `TenantOrderBoard._onReconnected`: without this, an order
    // that lands while the socket is down (app backgrounded, a dropped wifi
    // handoff) shows up fine on the board once reconnected via the same
    // gap-fill, but this listener — hearing only live `order.created`
    // events — never gets it, so the tenant sees the order with no chime,
    // banner or tray notification ever having fired for it.
    _reconnectedSubscription = realtime.reconnected.listen(
      (_) => _onReconnected(alerts, lifecycle),
    );

    ref.onDispose(() {
      _autoDismiss?.cancel();
      unawaited(_subscription?.cancel() ?? Future<void>.value());
      unawaited(_reconnectedSubscription?.cancel() ?? Future<void>.value());
    });

    return null;
  }

  void _announcePayload(
    Map<String, dynamic> payload,
    NewOrderAlerts alerts,
    AppLifecycleState? Function() lifecycle,
  ) {
    final TenantOrder order;
    try {
      order = TenantOrder.fromBroadcastPayload(payload);
    } on Object catch (error) {
      // A payload this can't parse is the board's problem to report, not the
      // alert's — and throwing from a stream listener would surface as an
      // uncaught async error rather than anything the tenant could act on.
      debugPrint('NewOrderAlertBanner: unparseable order.created — $error');
      return;
    }
    _announceOrder(order, alerts, lifecycle);
  }

  /// Fetches whatever `order.created` events landed while disconnected
  /// (`GET /v1/broadcast/replay`, confirmed to only ever carry that event —
  /// see `docs/api-reference.md`) and announces each one that hasn't
  /// already been alerted.
  Future<void> _onReconnected(
    NewOrderAlerts alerts,
    AppLifecycleState? Function() lifecycle,
  ) async {
    final afterId = _lastBroadcastEventId;
    // Nothing seen yet this session (e.g. the very first reconnect before
    // any live order ever arrived) — no cursor to replay from, same guard
    // as `TenantOrderBoard`.
    if (afterId == null) return;
    final branchId = ref.read(sessionBranchIdProvider);
    if (branchId == null) return;

    final List<TenantOrder> missed;
    try {
      missed = await ref
          .read(tenantOrderRepositoryProvider)
          .fetchMissedEvents(branchId: branchId, afterId: afterId);
    } on Object catch (error) {
      // Best-effort, same as the board's own gap-fill: a failure here costs
      // a possible missed alert, not a broken session.
      debugPrint('NewOrderAlertBanner: gap-fill failed — $error');
      return;
    }
    for (final order in missed) {
      _announceOrder(order, alerts, lifecycle);
    }
  }

  void _announceOrder(
    TenantOrder order,
    NewOrderAlerts alerts,
    AppLifecycleState? Function() lifecycle,
  ) {
    if (order.broadcastEventId case final id?) {
      if (_lastBroadcastEventId == null || id > _lastBroadcastEventId!) {
        _lastBroadcastEventId = id;
      }
    }
    // Already alerted — a live delivery this same order already arrived
    // through, or an overlapping gap-fill window. Firing again would
    // chime/notify twice for one order.
    if (!_alertedOrderIds.add(order.id)) return;

    final alert = NewOrderAlert.fromOrder(order);

    // Foreground and background are deliberately exclusive. Posting a tray
    // notification while the tenant is already looking at the order screen
    // is clutter, and chiming *and* letting the channel sound play would
    // double up — each path makes exactly one sound.
    final state = lifecycle();
    final foregrounded = state == null || state == AppLifecycleState.resumed;
    if (foregrounded) {
      unawaited(_guard(alerts.chime, 'chime'));
      show(alert);
    } else {
      unawaited(_guard(() => alerts.notify(alert), 'notify'));
    }
  }

  /// Shows [alert] as the banner, replacing whatever is up and restarting the
  /// auto-dismiss timer.
  void show(NewOrderAlert alert) {
    _autoDismiss?.cancel();
    state = alert;
    _autoDismiss = Timer(visibleFor, dismiss);
  }

  /// Hides the banner. Safe to call when nothing is showing.
  void dismiss() {
    _autoDismiss?.cancel();
    _autoDismiss = null;
    state = null;
  }

  /// Alerting is decoration on top of the order board — a plugin that fails
  /// to initialize, a device with no audio, a denied permission — none of
  /// that may take down the socket listener or leave an uncaught async error.
  /// Same best-effort contract as the realtime disconnect in `dioProvider`.
  Future<void> _guard(Future<void> Function() action, String label) async {
    try {
      await action();
    } on Object catch (error) {
      debugPrint('NewOrderAlertBanner: $label failed — $error');
    }
  }
}

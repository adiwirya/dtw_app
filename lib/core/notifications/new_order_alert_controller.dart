import 'dart:async';

import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/notifications/new_order_alert.dart';
import 'package:dtw_app/core/notifications/new_order_alerts.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
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
  Timer? _autoDismiss;

  /// How long the banner sits before dismissing itself. Long enough to read
  /// over a busy counter, short enough not to cover the order it announces.
  static const visibleFor = Duration(seconds: 6);

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

    // Channels/permission are set up once, up front, rather than on the first
    // order — asking for notification permission at the moment an order lands
    // would put a system dialog over the thing the tenant needs to act on.
    unawaited(_guard(alerts.initialize, 'initialize'));

    _subscription = ref
        .watch(tenantRealtimeServiceProvider)
        .orderCreated
        .listen((payload) => _announce(payload, alerts, lifecycle));

    ref.onDispose(() {
      _autoDismiss?.cancel();
      unawaited(_subscription?.cancel() ?? Future<void>.value());
    });

    return null;
  }

  void _announce(
    Map<String, dynamic> payload,
    NewOrderAlerts alerts,
    AppLifecycleState? Function() lifecycle,
  ) {
    final NewOrderAlert alert;
    try {
      final order = TenantOrder.fromBroadcastPayload(payload);
      alert = NewOrderAlert.fromOrder(order);
    } on Object catch (error) {
      // A payload this can't parse is the board's problem to report, not the
      // alert's — and throwing from a stream listener would surface as an
      // uncaught async error rather than anything the tenant could act on.
      debugPrint('NewOrderAlertBanner: unparseable order.created — $error');
      return;
    }

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

import 'dart:async';

import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/notifications/new_order_alert.dart';
import 'package:dtw_app/core/notifications/new_order_alert_controller.dart';
import 'package:dtw_app/core/notifications/new_order_alerts.dart';
import 'package:dtw_app/core/realtime/busboy_realtime_service.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/features/order/data/models/delivery.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'new_delivery_alert_controller.g.dart';

/// Chimes/notifies a busboy session when a new delivery lands
/// (`delivery.created` on `private-zone.<zoneId>`) — the busboy-side mirror
/// of `NewOrderAlertBanner`.
///
/// No in-app banner like the tenant side: a new delivery already appears
/// immediately at the top of the Order home's Baru sub-tab
/// (`OrderBoardNotifier._onDeliveryCreated`), so there is nothing this needs
/// to show — only the audio/tray-notification side effect.
@Riverpod(keepAlive: true)
class NewDeliveryAlert extends _$NewDeliveryAlert {
  StreamSubscription<Map<String, dynamic>>? _subscription;

  /// Delivery ids already alerted this session. There is no reconnect
  /// gap-fill on the busboy socket to create an overlapping window (see
  /// `BusboyRealtimeService.reconnected`), but a redelivered live event is
  /// still cheap to guard against — same reasoning as
  /// `NewOrderAlertBanner._alertedOrderIds`.
  final Set<String> _alertedDeliveryIds = {};

  @override
  void build() {
    // Only a logged-in busboy session has a delivery board to be alerted
    // about. `homePathFor(null, null)` — the pre-login/signed-out shape —
    // itself resolves to the busboy path (it's the router's default
    // fallback), unlike the tenant side where the equivalent fallback lands
    // on the *other* flavor's path for free. So this needs an explicit
    // `isLoggedInProvider` check that `NewOrderAlertBanner`'s tenant
    // equivalent doesn't: without it, every cold start would request
    // notification permission on the login screen before anyone has signed
    // in as anything.
    final isBusboy =
        ref.watch(isLoggedInProvider) &&
        homePathFor(
          role: ref.watch(sessionRoleProvider),
          branchId: ref.watch(sessionBranchIdProvider),
        ) ==
        AppRoutes.orderPath;
    if (!isBusboy) return;

    final alerts = ref.watch(busboyNewOrderAlertsProvider);
    final lifecycle = ref.watch(appLifecycleProvider);
    final realtime = ref.watch(busboyRealtimeServiceProvider);

    // Channel/permission are set up once, up front — same reasoning as the
    // tenant controller: asking at the moment a delivery lands would put a
    // system dialog over the thing the busboy needs to act on.
    unawaited(_guard(alerts.initialize, 'initialize'));

    _subscription = realtime.deliveryCreated.listen(
      (payload) => _announcePayload(payload, alerts, lifecycle),
    );

    ref.onDispose(() {
      unawaited(_subscription?.cancel() ?? Future<void>.value());
    });
  }

  void _announcePayload(
    Map<String, dynamic> payload,
    NewOrderAlerts alerts,
    AppLifecycleState? Function() lifecycle,
  ) {
    final Delivery delivery;
    try {
      delivery = Delivery.fromJson(payload);
    } on Object catch (error) {
      // A payload this can't parse is the board's problem to report, not the
      // alert's — throwing from a stream listener would surface as an
      // uncaught async error rather than anything the busboy could act on.
      debugPrint('NewDeliveryAlert: unparseable delivery.created — $error');
      return;
    }
    // Already alerted — chiming/notifying twice for one delivery.
    if (!_alertedDeliveryIds.add(delivery.id)) return;

    final alert = NewOrderAlert.fromDelivery(delivery);

    // Foreground and background are deliberately exclusive — see
    // `NewOrderAlertBanner._announceOrder` for the full reasoning.
    final state = lifecycle();
    final foregrounded = state == null || state == AppLifecycleState.resumed;
    if (foregrounded) {
      unawaited(_guard(alerts.chime, 'chime'));
    } else {
      unawaited(_guard(() => alerts.notify(alert), 'notify'));
    }
  }

  /// Same best-effort contract as `NewOrderAlertBanner._guard`: alerting is
  /// decoration on top of the delivery board, never allowed to take the
  /// socket listener down with it.
  Future<void> _guard(Future<void> Function() action, String label) async {
    try {
      await action();
    } on Object catch (error) {
      debugPrint('NewDeliveryAlert: $label failed — $error');
    }
  }
}

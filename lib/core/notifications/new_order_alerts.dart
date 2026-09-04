import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dtw_app/core/notifications/new_order_alert.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'new_order_alerts.g.dart';

/// Per-flavor sound + Android notification-channel configuration for
/// [PluginNewOrderAlerts]. Kept as a plain value type, separate from the
/// plugin class itself, so a test can inspect the asset path/channel id
/// without constructing a real `AudioPlayer`/notifications plugin (which
/// need a platform channel no plain `test()` has).
@immutable
class NewOrderAlertsConfig {
  const NewOrderAlertsConfig({
    required this.chimeAsset,
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    required this.channelSoundResource,
  });

  /// The tenant "new order" alert — `tenant_order.wav`.
  static const tenant = NewOrderAlertsConfig(
    chimeAsset: 'sounds/tenant_order.wav',
    // v1 was `new_order_v1`/`new_order` before the tenant and busboy sounds
    // split into separate files — bumped per [channelId]'s own rule since a
    // channel's sound is immutable once created.
    channelId: 'tenant_order_v1',
    channelName: 'Orderan Baru',
    channelDescription: 'Bunyi saat ada orderan baru masuk.',
    channelSoundResource: 'tenant_order',
  );

  /// The busboy "new delivery" alert — `new_order.wav` (the original shared
  /// chime file, now busboy-only since the tenant moved to its own sound).
  static const busboy = NewOrderAlertsConfig(
    chimeAsset: 'sounds/new_order.wav',
    channelId: 'busboy_new_order_v1',
    channelName: 'Order Baru',
    channelDescription: 'Bunyi saat ada order baru untuk diambil.',
    channelSoundResource: 'new_order',
  );

  /// Both the bundled asset (played by `chime()`) and the `res/raw` resource
  /// backing the notification channel are the same file, so a session hears
  /// the same sound whichever path fires.
  final String chimeAsset;

  /// Android notification channel id. The channel's sound is fixed at
  /// creation and immutable afterwards — changing [channelSoundResource]
  /// means bumping this, or existing installs keep playing the old one
  /// forever.
  final String channelId;
  final String channelName;
  final String channelDescription;

  /// Bare `res/raw` resource name (no extension) backing [channelId]'s sound.
  final String channelSoundResource;
}

/// Sounds and shows the "new order" alert. Abstracted behind an interface for
/// the same reason `TenantRealtimeService` is: the real implementation talks
/// to platform plugins, which no widget test can load — see
/// `test/support/fake_new_order_alerts.dart`.
abstract class NewOrderAlerts {
  /// Prepares the notification channels and permissions. Safe to call more
  /// than once; a failure here must not be fatal (see [PluginNewOrderAlerts]).
  Future<void> initialize();

  /// Plays the chime. Used when the app is on screen, where the banner —
  /// not a tray notification — is what the tenant sees.
  Future<void> chime();

  /// Posts an Android notification, which carries its own channel sound.
  /// Used when the app is NOT on screen.
  Future<void> notify(NewOrderAlert alert);

  /// Releases the audio handle. Called when the owning provider is disposed.
  Future<void> dispose();
}

/// [NewOrderAlerts] backed by `audioplayers` and
/// `flutter_local_notifications`.
///
/// Tenant and busboy each get their own [NewOrderAlertsConfig] (sound +
/// Android notification channel), rather than sharing one instance — a
/// busboy session must never be asked for notification permission (or hear
/// a chime) for a tenant order it doesn't have, and a channel's sound can't
/// be swapped after creation, so the two need separate channel ids
/// regardless.
///
/// **Android only, by decision.** The socket that triggers these alerts only
/// lives while the app process does, and iOS suspends a backgrounded socket
/// within seconds — so on iOS a tray notification would fire for a few
/// seconds after backgrounding and never again, which is worse than not
/// offering it. Reaching a closed iOS app needs APNs push originated by the
/// backend, not this class. [notify] is a no-op off Android; [chime] is not,
/// since in-app audio works everywhere.
class PluginNewOrderAlerts implements NewOrderAlerts {
  PluginNewOrderAlerts(
    this.config, {
    AudioPlayer? player,
    FlutterLocalNotificationsPlugin? notifications,
    bool? isAndroid,
  }) : _player = player ?? AudioPlayer(),
       _notifications = notifications ?? FlutterLocalNotificationsPlugin(),
       _isAndroid = isAndroid ?? Platform.isAndroid;

  final NewOrderAlertsConfig config;

  final AudioPlayer _player;
  final FlutterLocalNotificationsPlugin _notifications;
  final bool _isAndroid;
  var _ready = false;

  @override
  Future<void> initialize() async {
    if (_ready || !_isAndroid) return;
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        config.channelId,
        config.channelName,
        description: config.channelDescription,
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound(
          config.channelSoundResource,
        ),
      ),
    );
    // Android 13+ won't post anything until the user grants this. Declining
    // is a valid answer: the in-app banner and chime still work, so a refused
    // permission degrades the feature rather than breaking it.
    await android?.requestNotificationsPermission();
    _ready = true;
  }

  @override
  Future<void> chime() async {
    // `release: stop` keeps the decoded clip resident: orders arrive in
    // bursts, and re-decoding per event delays the chime past the moment it
    // is meant to mark.
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.stop();
    await _player.play(AssetSource(config.chimeAsset));
  }

  @override
  Future<void> notify(NewOrderAlert alert) async {
    if (!_isAndroid) return;
    await initialize();
    await _notifications.show(
      // A stable per-order id so a redelivered event replaces its own
      // notification instead of stacking a duplicate. Masked to 31 bits:
      // Android notification ids are Java ints, and `hashCode` can be
      // negative or exceed that on the web-compiled targets.
      id: alert.orderId.hashCode & 0x7fffffff,
      title: alert.title,
      body: alert.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          config.channelId,
          config.channelName,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.event,
        ),
      ),
      payload: alert.orderId,
    );
  }

  @override
  Future<void> dispose() => _player.dispose();
}

@Riverpod(keepAlive: true)
NewOrderAlerts newOrderAlerts(Ref ref) {
  final alerts = PluginNewOrderAlerts(NewOrderAlertsConfig.tenant);
  ref.onDispose(() => unawaited(alerts.dispose()));
  return alerts;
}

@Riverpod(keepAlive: true)
NewOrderAlerts busboyNewOrderAlerts(Ref ref) {
  final alerts = PluginNewOrderAlerts(NewOrderAlertsConfig.busboy);
  ref.onDispose(() => unawaited(alerts.dispose()));
  return alerts;
}

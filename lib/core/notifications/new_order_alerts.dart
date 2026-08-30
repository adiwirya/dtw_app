import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dtw_app/core/notifications/new_order_alert.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'new_order_alerts.g.dart';

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
/// **Android only, by decision.** The socket that triggers these alerts only
/// lives while the app process does, and iOS suspends a backgrounded socket
/// within seconds — so on iOS a tray notification would fire for a few
/// seconds after backgrounding and never again, which is worse than not
/// offering it. Reaching a closed iOS app needs APNs push originated by the
/// backend, not this class. [notify] is a no-op off Android; [chime] is not,
/// since in-app audio works everywhere.
class PluginNewOrderAlerts implements NewOrderAlerts {
  PluginNewOrderAlerts({
    AudioPlayer? player,
    FlutterLocalNotificationsPlugin? notifications,
    bool? isAndroid,
  }) : _player = player ?? AudioPlayer(),
       _notifications = notifications ?? FlutterLocalNotificationsPlugin(),
       _isAndroid = isAndroid ?? Platform.isAndroid;

  /// Both the bundled asset (played by [chime]) and the `res/raw` resource
  /// backing the notification channel are this one file, so the tenant hears
  /// the same sound whichever path fires.
  static const chimeAsset = 'sounds/new_order.wav';

  /// Android notification channel. The channel's sound is fixed at creation
  /// and immutable afterwards — changing the chime means bumping this id,
  /// or existing installs keep playing the old one forever.
  static const channelId = 'new_order_v1';
  static const channelName = 'Orderan Baru';

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
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'Bunyi saat ada orderan baru masuk.',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('new_order'),
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
    await _player.play(AssetSource(chimeAsset));
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
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
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
  final alerts = PluginNewOrderAlerts();
  ref.onDispose(() => unawaited(alerts.dispose()));
  return alerts;
}

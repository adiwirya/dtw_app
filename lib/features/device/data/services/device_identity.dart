import 'package:android_id/android_id.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_identity.g.dart';

/// This device's identity for `POST /v1/devices/register` — abstracted
/// behind an interface for the same reason `BusboyFcmService`/
/// `NewOrderAlerts` are: `android_id`/`firebase_messaging` need real
/// platform channels no widget test can load — see
/// `test/support/fake_device_identity.dart`.
abstract class DeviceIdentity {
  /// This device's Android ID (`Settings.Secure.ANDROID_ID`) —
  /// `POST /v1/devices/register`'s `device_id`. `null` off Android (the
  /// `android_id` plugin itself returns `null` there) — never reached in
  /// practice since the gate that calls this is Android-only.
  Future<String?> deviceId();

  /// This device's current FCM push token — `POST /v1/devices/register`'s
  /// `fcm_token`. Same underlying call `BusboyFcmService` uses for the
  /// logged-in-session token, but this is a separate, device-level
  /// registration with no session involved.
  Future<String?> fcmToken();
}

class PluginDeviceIdentity implements DeviceIdentity {
  PluginDeviceIdentity({AndroidId? androidId, FirebaseMessaging? messaging})
    : _androidId = androidId ?? const AndroidId(),
      _messagingOverride = messaging;

  final AndroidId _androidId;
  final FirebaseMessaging? _messagingOverride;

  // Deferred to first use for the same reason as `BusboyFcmService`'s
  // `_messaging` getter: resolving `FirebaseMessaging.instance` needs
  // `Firebase.initializeApp` to already have run.
  FirebaseMessaging get _messaging =>
      _messagingOverride ?? FirebaseMessaging.instance;

  @override
  Future<String?> deviceId() => _androidId.getId();

  @override
  Future<String?> fcmToken() => _messaging.getToken();
}

@Riverpod(keepAlive: true)
DeviceIdentity deviceIdentity(Ref ref) => PluginDeviceIdentity();

import 'dart:async';
import 'dart:io';

import 'package:dtw_app/core/realtime/reverb_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_reverb/laravel_reverb.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'busboy_realtime_service.g.dart';

/// Delivers real-time delivery events for the currently-connected busboy
/// zone. Abstracted behind an interface so tests can substitute a fake
/// instead of opening a real socket — see
/// `test/support/fake_busboy_realtime_service.dart`.
abstract class BusboyRealtimeService {
  /// Connects and subscribes to `private-zone.<zoneId>`, authenticating
  /// with [token] against `POST /broadcasting/auth`. Safe to call again
  /// with a new token/zoneId (e.g. after a fresh login) — implementations
  /// disconnect any existing session first.
  Future<void> connect({required String token, required String zoneId});

  /// Unsubscribes and disconnects. Safe to call when not connected.
  Future<void> disconnect();

  /// Emits the decoded payload of every `delivery.created` event received on
  /// the subscribed channel — the same shape as one `GET
  /// /api/v1/busboy/deliveries` list item.
  Stream<Map<String, dynamic>> get deliveryCreated;

  /// Emits the decoded payload of every `delivery.claimed` event — another
  /// busboy's (or this device's own) claim of a PENDING_PICKUP delivery.
  /// Same payload shape as [deliveryCreated]: the full, now-CLAIMED delivery.
  Stream<Map<String, dynamic>> get deliveryClaimed;

  /// Emits the decoded payload of every `delivery.completed` event — a
  /// CLAIMED delivery marked delivered. Same payload shape as
  /// [deliveryCreated]: the full, now-DELIVERED delivery.
  Stream<Map<String, dynamic>> get deliveryCompleted;

  /// Emits once each time the underlying connection re-establishes after a
  /// drop (not on the very first connect). There is no gap-fill/replay
  /// endpoint on the busboy API (unlike the tenant side's
  /// `/broadcast/replay`), so `OrderBoardNotifier` gap-fills by refetching
  /// the whole delivery list.
  Stream<void> get reconnected;

  /// Human-readable connection status/error lines, for surfacing socket
  /// health in the UI instead of only `debugPrint`.
  Stream<String> get statusMessages;
}

/// [BusboyRealtimeService] backed by a real `package:laravel_reverb` socket.
class ReverbBusboyRealtimeService implements BusboyRealtimeService {
  Reverb? _reverb;
  final _deliveryCreatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _deliveryClaimedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _deliveryCompletedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _reconnectedController = StreamController<void>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  @override
  Stream<Map<String, dynamic>> get deliveryCreated =>
      _deliveryCreatedController.stream;

  @override
  Stream<Map<String, dynamic>> get deliveryClaimed =>
      _deliveryClaimedController.stream;

  @override
  Stream<Map<String, dynamic>> get deliveryCompleted =>
      _deliveryCompletedController.stream;

  @override
  Stream<void> get reconnected => _reconnectedController.stream;

  @override
  Stream<String> get statusMessages => _statusController.stream;

  @override
  Future<void> connect({
    required String token,
    required String zoneId,
  }) async {
    await disconnect();

    final reverb = Reverb(
      host: ReverbConfig.host,
      port: ReverbConfig.port,
      appKey: ReverbConfig.appKey,
      // `useTls` currently equals `Reverb`'s default (`true`), but this
      // stays explicit so a future change to `ReverbConfig.useTls` is
      // honored without touching this call site.
      // ignore: avoid_redundant_argument_values
      useTls: ReverbConfig.useTls,
      authEndpoint: ReverbConfig.authEndpoint,
      authHeaders: () async => {'Authorization': 'Bearer $token'},
      // Package default tears the socket down on `paused` and reconnects on
      // `resumed`, so every event fired while backgrounded is lost (no
      // replay endpoint on the busboy API). `BusboyForegroundService` keeps
      // the Android process alive precisely so the socket can stay up — see
      // `ReverbTenantRealtimeService` for the same setting.
      handleAppLifecycle: !Platform.isAndroid,
      // ponytail: temporary diagnostics for background-socket drops (debug
      // builds only — socket frames can carry order data); remove once
      // realtime is confirmed stable on device.
      onLog: kDebugMode
          ? (message) => debugPrint('ReverbBusboyRealtimeService log: $message')
          : null,
      onError: (error, stackTrace) {
        debugPrint('ReverbBusboyRealtimeService error: $error');
        _statusController.add('Realtime error: $error');
      },
    );
    _reverb = reverb;

    reverb.onReconnected(() {
      _statusController.add('Realtime reconnected');
      debugPrint('Realtime reconnected');
      _reconnectedController.add(null);
    });

    await reverb.connect();
    _statusController.add('Realtime connected');
    debugPrint('Realtime connected');
    // The leading dot is required so the package treats this as the literal
    // broadcast name (`delivery.created`) rather than namespace-qualifying
    // it — see `ReverbTenantRealtimeService`'s `order.created` subscription
    // for the full explanation; the same package quirk applies here.
    reverb.private('zone.$zoneId')
      ..listen('.delivery.created', _deliveryCreatedController.add)
      ..listen('.delivery.claimed', _deliveryClaimedController.add)
      ..listen('.delivery.completed', _deliveryCompletedController.add);
  }

  @override
  Future<void> disconnect() async {
    final reverb = _reverb;
    _reverb = null;
    if (reverb != null) {
      await reverb.disconnect();
      reverb.dispose();
    }
  }
}

@Riverpod(keepAlive: true)
BusboyRealtimeService busboyRealtimeService(Ref ref) =>
    ReverbBusboyRealtimeService();

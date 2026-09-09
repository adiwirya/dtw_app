import 'dart:async';

import 'package:dtw_app/features/order/data/repositories/busboy_delivery_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'busboy_fcm_service.g.dart';

/// Registers this device's push token with the backend for the logged-in
/// busboy (`POST /v1/busboy/fcm-token`), so the backend can reach a killed
/// app — the one gap `PluginNewOrderAlerts` documents itself as unable to
/// cover (its socket-driven tray notification only lives while the app
/// process does).
///
/// Abstracted behind an interface for the same reason
/// `BusboyRealtimeService`/`NewOrderAlerts` are: `firebase_messaging` needs
/// real platform channels no widget test can load — see
/// `test/support/fake_busboy_fcm_service.dart`.
///
/// TODO(open-question): the backend hasn't specified a push payload shape
/// for a new/claimed/completed delivery yet, so this only registers the
/// token — a `notification` block in the payload still displays via the
/// OS's built-in FCM tray notification with zero extra code; a future
/// data-only payload will need an explicit `onMessage`/background handler
/// once the shape is confirmed (see `docs/busboy-missing-endpoints.md`).
// ignore: one_member_abstracts
abstract class BusboyFcmService {
  /// Requests notification permission (a no-op if already decided), then
  /// registers the current token and re-registers on every rotation. Safe to
  /// call more than once; a failure here must not be fatal — see
  /// [PluginBusboyFcmService].
  Future<void> initialize();
}

class PluginBusboyFcmService implements BusboyFcmService {
  PluginBusboyFcmService({
    required BusboyDeliveryRepository repository,
    FirebaseMessaging? messaging,
  }) : _repository = repository,
       _messagingOverride = messaging;

  final BusboyDeliveryRepository _repository;
  final FirebaseMessaging? _messagingOverride;
  StreamSubscription<String>? _refreshSubscription;

  // Deferred to first use inside `initialize()` rather than resolved at
  // construction: `busboyFcmServiceProvider` builds eagerly on first read,
  // and `FirebaseMessaging.instance` throws unless `Firebase.initializeApp`
  // has already run — fine in production (`bootstrap()` always runs it
  // first), but a widget test that reads this provider without a Firebase
  // test binding must still be able to construct the service and have only
  // `initialize()` (already fire-and-forget/`catchError`-wrapped at every
  // call site) fail.
  FirebaseMessaging get _messaging =>
      _messagingOverride ?? FirebaseMessaging.instance;

  @override
  Future<void> initialize() async {
    await _refreshSubscription?.cancel();

    final settings = await _messaging.requestPermission();
    // Declining is a valid answer, same contract as
    // `PluginNewOrderAlerts.initialize` — the app still works, it just won't
    // receive a push while closed.
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await _messaging.getToken();
    if (token != null) await _register(token);
    _refreshSubscription = _messaging.onTokenRefresh.listen(_register);
  }

  Future<void> _register(String token) async {
    try {
      await _repository.registerFcmToken(token);
    } on Object {
      // Best-effort, same fire-and-forget contract as the realtime
      // connect/foreground-service start calls this is wired alongside in
      // `AuthController.login` and `bootstrap.dart`.
    }
  }
}

@Riverpod(keepAlive: true)
BusboyFcmService busboyFcmService(Ref ref) => PluginBusboyFcmService(
  repository: ref.watch(busboyDeliveryRepositoryProvider),
);

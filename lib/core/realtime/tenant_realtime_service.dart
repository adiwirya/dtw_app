import 'dart:async';

import 'package:dtw_app/core/realtime/reverb_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_reverb/laravel_reverb.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tenant_realtime_service.g.dart';

/// Delivers real-time order events for the currently-connected tenant
/// branch. Abstracted behind an interface so tests can substitute a fake
/// instead of opening a real socket — see
/// `test/support/fake_tenant_realtime_service.dart`.
abstract class TenantRealtimeService {
  /// Connects and subscribes to `private-branch.<branchId>`, authenticating
  /// with [token] against `POST /broadcasting/auth`. Safe to call again
  /// with a new token/branchId (e.g. after a fresh login) — implementations
  /// disconnect any existing session first.
  Future<void> connect({required String token, required String branchId});

  /// Unsubscribes and disconnects. Safe to call when not connected.
  Future<void> disconnect();

  /// Emits the decoded payload of every `order.created` event received on
  /// the subscribed channel.
  Stream<Map<String, dynamic>> get orderCreated;

  /// Emits once each time the underlying connection re-establishes after a
  /// drop (not on the very first connect) — the signal to run the
  /// broadcast-replay gap-fill.
  Stream<void> get reconnected;

  /// Human-readable connection status/error lines, for surfacing socket
  /// health in the UI (e.g. a debug SnackBar) instead of only `debugPrint`.
  Stream<String> get statusMessages;
}

/// [TenantRealtimeService] backed by a real `package:laravel_reverb` socket.
class ReverbTenantRealtimeService implements TenantRealtimeService {
  Reverb? _reverb;
  final _orderCreatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _reconnectedController = StreamController<void>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  @override
  Stream<Map<String, dynamic>> get orderCreated =>
      _orderCreatedController.stream;

  @override
  Stream<void> get reconnected => _reconnectedController.stream;

  @override
  Stream<String> get statusMessages => _statusController.stream;

  @override
  Future<void> connect({
    required String token,
    required String branchId,
  }) async {
    await disconnect();

    final reverb = Reverb(
      host: ReverbConfig.host,
      port: ReverbConfig.port,
      appKey: ReverbConfig.appKey,
      // `useTls` currently equals `Reverb`'s default (`true`), but this
      // stays explicit so a future change to `ReverbConfig.useTls` (e.g. a
      // non-TLS staging server) is honored without touching this call site.
      // ignore: avoid_redundant_argument_values
      useTls: ReverbConfig.useTls,
      authEndpoint: ReverbConfig.authEndpoint,
      authHeaders: () async => {'Authorization': 'Bearer $token'},
      // `connect()`'s Future completes normally on both success AND a fatal
      // give-up (e.g. a rejected auth handshake) — every failure, including
      // a rejected private-channel subscription, only ever surfaces through
      // this callback. Without it, a broken connection looks identical to a
      // working one: no exception, no thrown error, just a socket that never
      // delivers anything.
      onError: (error, stackTrace) {
        debugPrint('ReverbTenantRealtimeService error: $error');
        _statusController.add('Realtime error: $error');
      },
    );
    _reverb = reverb;

    // `onReconnected` is the package's purpose-built signal for "a dropped
    // socket just came back up, with every channel resubscribed" — unlike
    // the raw `states` stream, it deliberately never fires on the first
    // connect, which matches this interface's contract exactly.
    reverb.onReconnected(() {
      _statusController.add('Realtime reconnected');
      _reconnectedController.add(null);
    });

    await reverb.connect();
    _statusController.add('Realtime connected');
    // The leading dot tells the package this is a literal broadcast name
    // (Laravel's `broadcastAs('order.created')`), not a class name to
    // namespace-qualify — without it, `resolveEventName` silently listens
    // for `App\Events\order.created` instead of the `order.created` the
    // server actually sends, and every event is dropped with no error at
    // all (dispatch finds no matching listener and just returns).
    reverb
        .private('branch.$branchId')
        .listen('.order.created', _orderCreatedController.add);
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
TenantRealtimeService tenantRealtimeService(Ref ref) =>
    ReverbTenantRealtimeService();

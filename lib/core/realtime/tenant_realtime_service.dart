import 'dart:async';

import 'package:dtw_app/core/realtime/reverb_config.dart';
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
}

/// [TenantRealtimeService] backed by a real `package:laravel_reverb` socket.
class ReverbTenantRealtimeService implements TenantRealtimeService {
  Reverb? _reverb;
  final _orderCreatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _reconnectedController = StreamController<void>.broadcast();

  @override
  Stream<Map<String, dynamic>> get orderCreated =>
      _orderCreatedController.stream;

  @override
  Stream<void> get reconnected => _reconnectedController.stream;

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
    );
    _reverb = reverb;

    // `onReconnected` is the package's purpose-built signal for "a dropped
    // socket just came back up, with every channel resubscribed" — unlike
    // the raw `states` stream, it deliberately never fires on the first
    // connect, which matches this interface's contract exactly.
    reverb.onReconnected(() => _reconnectedController.add(null));

    await reverb.connect();
    reverb
        .private('branch.$branchId')
        .listen('order.created', _orderCreatedController.add);
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

import 'dart:async';

import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';

/// In-memory [TenantRealtimeService] test double. Tests push events with
/// [emitOrderCreated]/[emitReconnected]; [connectCalls] and
/// [disconnectCallCount] let tests assert connect/disconnect lifecycle
/// wiring without a real socket. Set [connectError] to make [connect] throw,
/// simulating a socket/auth failure during login.
class FakeTenantRealtimeService implements TenantRealtimeService {
  final List<({String token, String branchId})> connectCalls = [];
  int disconnectCallCount = 0;
  Exception? connectError;

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
    connectCalls.add((token: token, branchId: branchId));
    final error = connectError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> disconnect() async {
    disconnectCallCount++;
  }

  void emitOrderCreated(Map<String, dynamic> payload) {
    _orderCreatedController.add(payload);
  }

  void emitReconnected() {
    _reconnectedController.add(null);
  }

  Future<void> close() async {
    await _orderCreatedController.close();
    await _reconnectedController.close();
    await _statusController.close();
  }
}

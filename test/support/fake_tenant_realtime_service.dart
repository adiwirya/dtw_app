import 'dart:async';

import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';

/// In-memory [TenantRealtimeService] test double. Tests push events with
/// [emitOrderCreated]/[emitReconnected]; [connectCalls] and
/// [disconnectCallCount] let tests assert connect/disconnect lifecycle
/// wiring without a real socket.
class FakeTenantRealtimeService implements TenantRealtimeService {
  final List<({String token, String branchId})> connectCalls = [];
  int disconnectCallCount = 0;

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
    connectCalls.add((token: token, branchId: branchId));
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
  }
}

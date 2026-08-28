import 'dart:async';

import 'package:dtw_app/core/realtime/busboy_realtime_service.dart';

/// In-memory [BusboyRealtimeService] test double. Tests push events with
/// [emitDeliveryCreated]/[emitReconnected]; [connectCalls] and
/// [disconnectCallCount] let tests assert connect/disconnect lifecycle
/// wiring without a real socket. Set [connectError] to make [connect] throw,
/// simulating a socket/auth failure during login.
class FakeBusboyRealtimeService implements BusboyRealtimeService {
  final List<({String token, String zoneId})> connectCalls = [];
  int disconnectCallCount = 0;
  Exception? connectError;

  final _deliveryCreatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _reconnectedController = StreamController<void>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  @override
  Stream<Map<String, dynamic>> get deliveryCreated =>
      _deliveryCreatedController.stream;

  @override
  Stream<void> get reconnected => _reconnectedController.stream;

  @override
  Stream<String> get statusMessages => _statusController.stream;

  @override
  Future<void> connect({
    required String token,
    required String zoneId,
  }) async {
    connectCalls.add((token: token, zoneId: zoneId));
    final error = connectError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> disconnect() async {
    disconnectCallCount++;
  }

  void emitDeliveryCreated(Map<String, dynamic> payload) {
    _deliveryCreatedController.add(payload);
  }

  void emitReconnected() {
    _reconnectedController.add(null);
  }

  Future<void> close() async {
    await _deliveryCreatedController.close();
    await _reconnectedController.close();
    await _statusController.close();
  }
}

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
  final _deliveryClaimedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _deliveryCompletedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _confirmationCreatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _confirmationClaimedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _confirmationResolvedController =
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
  Stream<Map<String, dynamic>> get confirmationCreated =>
      _confirmationCreatedController.stream;

  @override
  Stream<Map<String, dynamic>> get confirmationClaimed =>
      _confirmationClaimedController.stream;

  @override
  Stream<Map<String, dynamic>> get confirmationResolved =>
      _confirmationResolvedController.stream;

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

  void emitDeliveryClaimed(Map<String, dynamic> payload) {
    _deliveryClaimedController.add(payload);
  }

  void emitDeliveryCompleted(Map<String, dynamic> payload) {
    _deliveryCompletedController.add(payload);
  }

  void emitConfirmationCreated(Map<String, dynamic> payload) {
    _confirmationCreatedController.add(payload);
  }

  void emitConfirmationClaimed(Map<String, dynamic> payload) {
    _confirmationClaimedController.add(payload);
  }

  void emitConfirmationResolved(Map<String, dynamic> payload) {
    _confirmationResolvedController.add(payload);
  }

  void emitReconnected() {
    _reconnectedController.add(null);
  }

  Future<void> close() async {
    await _deliveryCreatedController.close();
    await _deliveryClaimedController.close();
    await _deliveryCompletedController.close();
    await _confirmationCreatedController.close();
    await _confirmationClaimedController.close();
    await _confirmationResolvedController.close();
    await _reconnectedController.close();
    await _statusController.close();
  }
}

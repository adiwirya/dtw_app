import 'package:dtw_app/core/notifications/new_order_alert.dart';
import 'package:dtw_app/core/notifications/new_order_alerts.dart';

/// In-memory [NewOrderAlerts] test double. Records which of the two mutually
/// exclusive paths fired; set [chimeError]/[notifyError] to prove a failing
/// plugin can't take the socket listener down with it.
class FakeNewOrderAlerts implements NewOrderAlerts {
  int initializeCallCount = 0;
  int chimeCallCount = 0;
  final List<NewOrderAlert> notified = [];
  Exception? initializeError;
  Exception? chimeError;
  Exception? notifyError;
  bool disposed = false;

  @override
  Future<void> initialize() async {
    initializeCallCount++;
    final error = initializeError;
    if (error != null) throw error;
  }

  @override
  Future<void> chime() async {
    chimeCallCount++;
    final error = chimeError;
    if (error != null) throw error;
  }

  @override
  Future<void> notify(NewOrderAlert alert) async {
    notified.add(alert);
    final error = notifyError;
    if (error != null) throw error;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

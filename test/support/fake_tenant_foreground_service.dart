import 'package:dtw_app/core/notifications/tenant_foreground_service.dart';

/// In-memory [TenantForegroundService] test double. Tracks call counts so a
/// test can assert start/stop lifecycle wiring without a real platform
/// channel.
class FakeTenantForegroundService implements TenantForegroundService {
  int startCallCount = 0;
  int stopCallCount = 0;

  @override
  Future<void> start() async {
    startCallCount++;
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
  }
}

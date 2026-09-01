import 'package:dtw_app/core/notifications/busboy_foreground_service.dart';

/// In-memory [BusboyForegroundService] test double. Tracks call counts so a
/// test can assert start/stop lifecycle wiring without a real platform
/// channel.
class FakeBusboyForegroundService implements BusboyForegroundService {
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

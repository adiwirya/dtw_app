import 'package:dtw_app/core/notifications/busboy_fcm_service.dart';

/// In-memory [BusboyFcmService] test double — [initializeCallCount] lets
/// tests assert it was wired into the login/restore flow without touching
/// real `firebase_messaging` platform channels.
class FakeBusboyFcmService implements BusboyFcmService {
  int initializeCallCount = 0;

  @override
  Future<void> initialize() async {
    initializeCallCount++;
  }
}

import 'package:dtw_app/features/device/data/services/device_identity.dart';

/// In-memory [DeviceIdentity] test double — no platform channel involved.
/// Both fields default to `null`, which drives
/// `DeviceOnboardingScreen`'s "unavailable" failure path.
class FakeDeviceIdentity implements DeviceIdentity {
  FakeDeviceIdentity({this._deviceId, this._fcmToken});

  final String? _deviceId;
  final String? _fcmToken;

  @override
  Future<String?> deviceId() async => _deviceId;

  @override
  Future<String?> fcmToken() async => _fcmToken;
}

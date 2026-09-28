import 'package:dio/dio.dart';
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/network/dio_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_repository.g.dart';

/// Static key the backend expects on every `POST /v1/devices/register`
/// call's `X-Device-Key` header — configured server-side as
/// `DEVICE_REGISTRATION_KEY` (see `api-auth-device-external.md`). Every
/// device registering itself sends this same value; it is not a
/// per-session/user secret.
///
/// PLACEHOLDER — replace with the real value before this ships. Every
/// register call 401s with this value in place.
const _deviceRegistrationKey = 'CHANGE_ME_DEVICE_REGISTRATION_KEY';

class DeviceRepository {
  const DeviceRepository({required this._dio});

  final Dio _dio;

  /// `POST /v1/devices/register` — idempotent/upsert by [deviceId]: a new
  /// `device_id` creates a device with no branch assignment yet (an admin
  /// assigns one later via the CMS); an existing `device_id` only has its
  /// `fcm_token`/[name] updated, never its branch assignment. [name] is
  /// omitted from the request entirely when null (server default: filled
  /// in later via the CMS, never by this device itself).
  Future<void> register({
    required String deviceId,
    required String fcmToken,
    String? name,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/v1/devices/register',
        data: {
          'device_id': deviceId,
          'fcm_token': fcmToken,
          'name': ?name,
        },
        options: Options(headers: {'X-Device-Key': _deviceRegistrationKey}),
      );
    } on DioException catch (error) {
      throw mapDioError(
        error,
        unauthorizedMessage: (_) => 'Konfigurasi perangkat tidak valid.',
      );
    }
  }
}

@riverpod
DeviceRepository deviceRepository(Ref ref) =>
    DeviceRepository(dio: ref.watch(dioProvider));

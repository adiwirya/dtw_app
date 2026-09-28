import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/features/device/data/repositories/device_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/canned_dio.dart';

Map<String, dynamic> _okEnvelope() => {
  'meta': {
    'success': true,
    'message': 'Device registered successfully.',
    'code': 201,
    'trace_id': 'abc',
  },
  'data': {
    'id': 'uuid-device-1',
    'tenant_branch_id': null,
    'device_id': 'SN-A1B2C3D4',
    'name': null,
    'description': null,
    'created_by': null,
    'updated_by': null,
    'created_at': '2026-09-28T00:00:00.000000Z',
    'updated_at': '2026-09-28T00:00:00.000000Z',
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('register completes without throwing on success', () async {
    final repository = DeviceRepository(dio: cannedDio(201, _okEnvelope()));

    await repository.register(deviceId: 'SN-A1B2C3D4', fcmToken: 'tok-1');
  });

  test('register sends device_id/fcm_token and the X-Device-Key header',
      () async {
    final dio = cannedDio(201, _okEnvelope());
    final repository = DeviceRepository(dio: dio);

    await repository.register(deviceId: 'SN-A1B2C3D4', fcmToken: 'tok-1');

    final lastRequest = (dio.httpClientAdapter as CannedAdapter).lastRequest;
    expect(lastRequest!.path, '/v1/devices/register');
    expect(lastRequest.data, {
      'device_id': 'SN-A1B2C3D4',
      'fcm_token': 'tok-1',
    });
    expect(lastRequest.headers['X-Device-Key'], isNotNull);
  });

  test('register omits the name key entirely when not given', () async {
    final dio = cannedDio(201, _okEnvelope());
    final repository = DeviceRepository(dio: dio);

    await repository.register(deviceId: 'SN-A1B2C3D4', fcmToken: 'tok-1');

    final lastRequest = (dio.httpClientAdapter as CannedAdapter).lastRequest;
    expect((lastRequest!.data as Map).containsKey('name'), isFalse);
  });

  test('register sends name when given', () async {
    final dio = cannedDio(201, _okEnvelope());
    final repository = DeviceRepository(dio: dio);

    await repository.register(
      deviceId: 'SN-A1B2C3D4',
      fcmToken: 'tok-1',
      name: 'Kasir Lantai 1',
    );

    final lastRequest = (dio.httpClientAdapter as CannedAdapter).lastRequest;
    expect((lastRequest!.data as Map)['name'], 'Kasir Lantai 1');
  });

  test('a 401 (bad X-Device-Key) throws with the device-specific message',
      () async {
    final repository = DeviceRepository(
      dio: cannedDio(401, {
        'meta': {
          'success': false,
          'message': 'Unauthorized',
          'code': 401,
          'trace_id': 'abc',
        },
        'errors': null,
      }),
    );

    await expectLater(
      repository.register(deviceId: 'SN-A1B2C3D4', fcmToken: 'tok-1'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Konfigurasi perangkat tidak valid.',
        ),
      ),
    );
  });

  test('a 422 throws a mapped ApiException', () async {
    final repository = DeviceRepository(
      dio: cannedDio(422, {
        'meta': {
          'success': false,
          'message': 'Validation',
          'code': 422,
          'trace_id': 'abc',
        },
        'errors': {
          'device_id': ['The device id field is required.'],
        },
      }),
    );

    await expectLater(
      repository.register(deviceId: '', fcmToken: 'tok-1'),
      throwsA(isA<ApiException>()),
    );
  });

  test('a network failure throws a mapped ApiException', () async {
    final repository = DeviceRepository(
      dio: cannedDio(500, {
        'meta': {
          'success': false,
          'message': 'Error',
          'code': 500,
          'trace_id': 'abc',
        },
      }),
    );

    await expectLater(
      repository.register(deviceId: 'SN-A1B2C3D4', fcmToken: 'tok-1'),
      throwsA(isA<ApiException>()),
    );
  });
}

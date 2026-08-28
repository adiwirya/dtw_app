import 'package:dio/dio.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/network/dio_provider.dart';
import 'package:dtw_app/core/realtime/busboy_realtime_service.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/canned_dio.dart';
import '../../support/fake_busboy_realtime_service.dart';
import '../../support/fake_local_storage.dart';
import '../../support/fake_tenant_realtime_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('attaches the stored token as a Bearer header', () async {
    final storage = FakeLocalStorage();
    await storage.write(authTokenStorageKey, 'tok_abc');
    final container = ProviderContainer(
      overrides: [localStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    final dio = container.read(dioProvider);
    final adapter = CannedAdapter(200, {'ok': true});
    dio.httpClientAdapter = adapter;

    await dio.get<void>('/v1/whatever');

    expect(adapter.lastRequest?.headers['Authorization'], 'Bearer tok_abc');
  });

  test('401 clears the token and flips isLoggedInProvider to false', () async {
    final storage = FakeLocalStorage();
    await storage.write(authTokenStorageKey, 'tok_abc');
    final container = ProviderContainer(
      overrides: [localStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    container.read(isLoggedInProvider.notifier).state = true;

    final dio = container.read(dioProvider);
    dio.httpClientAdapter = CannedAdapter(401, {'errors': null});

    try {
      await dio.get<void>('/v1/whatever');
    } on DioException catch (_) {
      // Expected: the canned adapter returns 401, which Dio surfaces as an error.
    }

    expect(await storage.read(authTokenStorageKey), isNull);
    expect(container.read(isLoggedInProvider), isFalse);
  });

  test('401 also disconnects the realtime socket', () async {
    final storage = FakeLocalStorage();
    await storage.write(authTokenStorageKey, 'tok_abc');
    final realtime = FakeTenantRealtimeService();
    addTearDown(realtime.close);
    final busboyRealtime = FakeBusboyRealtimeService();
    addTearDown(busboyRealtime.close);
    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        tenantRealtimeServiceProvider.overrideWithValue(realtime),
        busboyRealtimeServiceProvider.overrideWithValue(busboyRealtime),
      ],
    );
    addTearDown(container.dispose);
    container.read(isLoggedInProvider.notifier).state = true;

    final dio = container.read(dioProvider)
      ..httpClientAdapter = CannedAdapter(401, {'errors': null});

    try {
      await dio.get<void>('/v1/whatever');
    } on DioException catch (_) {
      // Expected: the canned adapter returns 401.
    }

    expect(container.read(isLoggedInProvider), isFalse);
    expect(realtime.disconnectCallCount, 1);
    expect(busboyRealtime.disconnectCallCount, 1);
  });
}

import 'package:dio/dio.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/network/dio_provider.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/canned_dio.dart';
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

  // Session expiry must clear the FLAVOR as well. `App` renders whichever
  // router `appFlavorProvider` names, so a 401 that only cleared the login
  // flag left an expired tenant session on `tenantRouter`, redirecting to
  // that router's own `/login` rather than the real shared `LoginScreen`.
  test('401 also resets appFlavorProvider to busboy', () async {
    final storage = FakeLocalStorage();
    await storage.write(authTokenStorageKey, 'tok_abc');
    final realtime = FakeTenantRealtimeService();
    addTearDown(realtime.close);
    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        tenantRealtimeServiceProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(container.dispose);
    container.read(isLoggedInProvider.notifier).state = true;
    container.read(appFlavorProvider.notifier).state = AppFlavor.tenant;

    final dio = container.read(dioProvider)
      ..httpClientAdapter = CannedAdapter(401, {'errors': null});

    try {
      await dio.get<void>('/v1/whatever');
    } on DioException catch (_) {
      // Expected: the canned adapter returns 401.
    }

    expect(container.read(appFlavorProvider), AppFlavor.busboy);
    expect(container.read(isLoggedInProvider), isFalse);
    // The realtime socket is torn down on expiry too.
    expect(realtime.disconnectCallCount, 1);
  });
}

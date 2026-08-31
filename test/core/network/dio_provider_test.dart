import 'dart:convert';

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

/// An adapter that fails with [DioExceptionType.connectionError] for the
/// first [failTimes] calls, then answers with [body].
class _FlakyThenOkAdapter implements HttpClientAdapter {
  _FlakyThenOkAdapter({required this.failTimes, required this.body});

  final int failTimes;
  final Object? body;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    if (callCount <= failTimes) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'simulated flaky connection',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('retries a connection failure instead of surfacing it', () {
    test('succeeds after one transient connection error', () async {
      final storage = FakeLocalStorage();
      final container = ProviderContainer(
        overrides: [localStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      final dio = container.read(dioProvider);
      final adapter = _FlakyThenOkAdapter(failTimes: 1, body: {'ok': true});
      dio.httpClientAdapter = adapter;

      final response = await dio.get<Map<String, dynamic>>('/v1/whatever');

      expect(response.data, {'ok': true});
      // The first call failed; the retry is what actually got the 200.
      expect(adapter.callCount, 2);
    });

    test('gives up after the retry budget and surfaces the failure',
        () async {
      final storage = FakeLocalStorage();
      final container = ProviderContainer(
        overrides: [localStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      final dio = container.read(dioProvider);
      final adapter = _FlakyThenOkAdapter(failTimes: 99, body: {'ok': true});
      dio.httpClientAdapter = adapter;

      await expectLater(
        dio.get<void>('/v1/whatever'),
        throwsA(isA<DioException>()),
      );
      // Initial attempt + 2 retries, then it gives up.
      expect(adapter.callCount, 3);
    });
  });

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
    container.read(sessionRoleProvider.notifier).state = 'tenant_keeper';
    container.read(sessionUsernameProvider.notifier).state = 'janji';
    container.read(sessionBranchIdProvider.notifier).state = 'branch-1';
    container.read(sessionZoneIdProvider.notifier).state = 'zone-1';

    final dio = container.read(dioProvider);
    dio.httpClientAdapter = CannedAdapter(401, {'errors': null});

    try {
      await dio.get<void>('/v1/whatever');
    } on DioException catch (_) {
      // Expected: the canned adapter returns 401, which Dio surfaces as an error.
    }

    expect(await storage.read(authTokenStorageKey), isNull);
    expect(container.read(isLoggedInProvider), isFalse);
    // The whole session context goes, not just the token — otherwise the
    // router would keep routing on a stale role after the session expired.
    expect(container.read(sessionRoleProvider), isNull);
    expect(container.read(sessionUsernameProvider), isNull);
    expect(container.read(sessionBranchIdProvider), isNull);
    expect(container.read(sessionZoneIdProvider), isNull);
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

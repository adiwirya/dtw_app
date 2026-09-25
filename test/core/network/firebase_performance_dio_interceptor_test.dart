import 'package:dio/dio.dart';
import 'package:dtw_app/core/network/firebase_performance_dio_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/canned_dio.dart';

// No Firebase app is initialized anywhere in this test suite (the same
// environment every other widget/unit test already runs under), so
// `FirebasePerformance.instance` throws when the interceptor reaches for it.
// The interceptor's whole contract is that this must degrade to a no-op,
// never fail the real request — exercised here through an actual Dio
// round-trip rather than calling the interceptor's methods directly, since
// `HttpMetric`/`FirebasePerformance` have no injectable fake without a real
// platform binding.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Dio dioWithInterceptor(int statusCode, Object? body) {
    return cannedDio(statusCode, body)
      ..interceptors.add(FirebasePerformanceDioInterceptor());
  }

  test('a successful request completes normally without a Firebase app',
      () async {
    final dio = dioWithInterceptor(200, {'ok': true});

    final response = await dio.get<Map<String, dynamic>>('/v1/whatever');

    expect(response.statusCode, 200);
    expect(response.data, {'ok': true});
  });

  test('a failed request still surfaces its DioException, not a metric '
      'failure', () async {
    final dio = dioWithInterceptor(500, {'errors': null});

    await expectLater(
      dio.get<void>('/v1/whatever'),
      throwsA(isA<DioException>()),
    );
  });

  // `_httpMethod` maps every verb Dio can issue to firebase_performance's
  // HttpMethod enum, defaulting unrecognised ones to GET — exercised here
  // through the real request path (the mapped value itself isn't observable
  // without a Firebase app) so each switch branch actually runs.
  for (final method in ['POST', 'PUT', 'PATCH', 'DELETE', 'HEAD']) {
    test(
      '$method requests complete normally without a Firebase app',
      () async {
        final dio = dioWithInterceptor(200, {'ok': true});

        final response = await dio.request<Map<String, dynamic>>(
          '/v1/whatever',
          options: Options(method: method),
        );

        expect(response.statusCode, 200);
      },
    );
  }
}

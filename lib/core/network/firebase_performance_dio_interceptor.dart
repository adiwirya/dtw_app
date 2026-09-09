import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';

/// Wraps every request in a Firebase Performance [HttpMetric].
///
/// `firebase_performance`'s automatic network monitoring only instruments
/// native HTTP stacks (OkHttp/NSURLSession) at the bytecode/binary level —
/// Dio's default adapter rides `dart:io HttpClient`, which never touches
/// those, so nothing is captured without this interceptor doing it by hand.
///
/// Every call is wrapped in its own try/catch: a metric failing to
/// start/stop (e.g. no Firebase app in a widget test, which has no test
/// binding for `firebase_performance`'s platform channel) must never turn a
/// real, successful request into a failed one.
class FirebasePerformanceDioInterceptor extends Interceptor {
  FirebasePerformanceDioInterceptor({FirebasePerformance? performance})
    : _performanceOverride = performance;

  final FirebasePerformance? _performanceOverride;

  // Deferred to first use for the same reason as `BusboyFcmService`'s
  // `_messaging` getter: resolving `FirebasePerformance.instance` needs
  // `Firebase.initializeApp` to already have run.
  FirebasePerformance get _performance =>
      _performanceOverride ?? FirebasePerformance.instance;

  static const _metricKey = '_firebasePerformanceHttpMetric';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final metric = _performance.newHttpMetric(
        options.uri.toString(),
        _httpMethod(options.method),
      );
      await metric.start();
      options.extra[_metricKey] = metric;
    } on Object {
      // Best-effort — see class doc.
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    await _stop(
      response.requestOptions,
      statusCode: response.statusCode,
      contentType: response.headers.value(Headers.contentTypeHeader),
    );
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    await _stop(
      err.requestOptions,
      statusCode: err.response?.statusCode,
      contentType: err.response?.headers.value(Headers.contentTypeHeader),
    );
    handler.next(err);
  }

  Future<void> _stop(
    RequestOptions options, {
    required int? statusCode,
    required String? contentType,
  }) async {
    final metric = options.extra.remove(_metricKey) as HttpMetric?;
    if (metric == null) return;
    try {
      if (statusCode != null) metric.httpResponseCode = statusCode;
      if (contentType != null) metric.responseContentType = contentType;
      await metric.stop();
    } on Object {
      // Best-effort — see class doc.
    }
  }

  HttpMethod _httpMethod(String method) => switch (method.toUpperCase()) {
    'GET' => HttpMethod.Get,
    'POST' => HttpMethod.Post,
    'PUT' => HttpMethod.Put,
    'PATCH' => HttpMethod.Patch,
    'DELETE' => HttpMethod.Delete,
    'HEAD' => HttpMethod.Head,
    'OPTIONS' => HttpMethod.Options,
    'CONNECT' => HttpMethod.Connect,
    'TRACE' => HttpMethod.Trace,
    // Dio never issues anything outside the above; a defensive fallback
    // rather than a thrown error keeps a metric failure non-fatal per the
    // class doc.
    _ => HttpMethod.Get,
  };
}

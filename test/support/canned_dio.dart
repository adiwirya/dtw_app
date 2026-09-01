import 'dart:convert';

import 'package:dio/dio.dart';

/// An [HttpClientAdapter] that always returns [statusCode]/[body], so tests
/// can exercise real [Dio]/repository code without a network call. Records
/// [lastRequest] for header/URL assertions.
class CannedAdapter implements HttpClientAdapter {
  CannedAdapter(this.statusCode, this.body);

  final int statusCode;
  final Object? body;
  RequestOptions? lastRequest;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    callCount++;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A [Dio] wired to a fresh [CannedAdapter] returning [statusCode]/[body].
Dio cannedDio(
  int statusCode,
  Object? body, {
  String baseUrl = 'https://dtw-cms.gadingemerald.com/api',
}) {
  return Dio(BaseOptions(baseUrl: baseUrl))
    ..httpClientAdapter = CannedAdapter(statusCode, body);
}

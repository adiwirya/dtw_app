import 'dart:convert';

import 'package:dio/dio.dart';

/// An [HttpClientAdapter] that returns a different canned status/body per
/// request-path prefix — for repositories/providers that make more than one
/// GET/PATCH call to different endpoints in a single build (a plain
/// single-response `cannedDio` can't tell those calls apart).
///
/// Keys are matched two ways, in this order: `"METHOD path"` (e.g.
/// `'POST /v1/modifier-groups'`) for when the same path is hit with different
/// methods for different purposes (a list GET vs. a create POST), or a plain
/// path prefix (e.g. `'/v1/products'`, method-agnostic) otherwise. Put the
/// more specific key first when a path is a prefix of another registered key.
class RoutedAdapter implements HttpClientAdapter {
  RoutedAdapter(this.responses);

  final Map<String, (int, Object?)> responses;
  RequestOptions? lastRequest;

  /// Every request seen, in order — for tests asserting a sequence of calls
  /// (e.g. a `PUT` per already-saved option, a `POST` per new one) where
  /// [lastRequest] alone can't distinguish them.
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    requests.add(options);
    final methodPath = '${options.method} ${options.path}';
    final match = responses.entries.firstWhere(
      (e) => methodPath.startsWith(e.key) || options.path.startsWith(e.key),
      orElse: () => throw StateError('No canned response for $methodPath'),
    );
    final (statusCode, body) = match.value;
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

/// A [Dio] wired to a fresh [RoutedAdapter] — keyed by path prefix, e.g.
/// `{'/v1/products': (200, ...), 'GET /v1/products/p1': (200, ...)}`.
Dio routedDio(
  Map<String, (int, Object?)> responses, {
  String baseUrl = 'https://dtw-cms.gadingemerald.com/api',
}) {
  return Dio(BaseOptions(baseUrl: baseUrl))
    ..httpClientAdapter = RoutedAdapter(responses);
}

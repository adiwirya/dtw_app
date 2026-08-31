import 'package:dio/dio.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/realtime/busboy_realtime_service.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

/// Downtown CMS / DT POS backend base URL — same host for both busboy and
/// tenant flavors; they differ only in which paths they call
/// (`/v1/...` vs `/v1/storefront/...`).
const _baseUrl = 'https://dtw-cms.gadingemerald.com/api';

@riverpod
Dio dio(Ref ref) {
  final dio = Dio(BaseOptions(baseUrl: _baseUrl))
    ..interceptors.add(LogInterceptor());

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await ref
            .read(localStorageProvider)
            .read(authTokenStorageKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await ref.read(localStorageProvider).delete(authTokenStorageKey);
          // Best-effort cleanup — a disconnect failure must never stop
          // `handler.next(error)` below from running, or every authenticated
          // request's 401-handling breaks with it.
          try {
            await ref.read(tenantRealtimeServiceProvider).disconnect();
          } on Object catch (_) {
            // Swallowed intentionally — see comment above.
          }
          try {
            await ref.read(busboyRealtimeServiceProvider).disconnect();
          } on Object catch (_) {
            // Swallowed intentionally — see comment above.
          }
          ref.read(isLoggedInProvider.notifier).state = false;
          ref.read(sessionUsernameProvider.notifier).state = null;
          ref.read(sessionRoleProvider.notifier).state = null;
          ref.read(sessionBranchIdProvider.notifier).state = null;
          ref.read(sessionZoneIdProvider.notifier).state = null;
        }
        handler.next(error);
      },
    ),
  );

  // Added last so it sees a failure first (Dio runs `onError` in reverse of
  // insertion order) — a flaky request gets a couple of quiet retries before
  // it ever reaches the 401 handler or `mapDioError`'s "Tidak bisa
  // terhubung ke server" message.
  dio.interceptors.add(_RetryOnConnectionFailureInterceptor(dio));

  return dio;
}

/// Retries a request when it failed without ever getting a server response —
/// a dropped wifi handoff, a slow cell handover — instead of surfacing
/// "Tidak bisa terhubung ke server" for what's often just one bad beat.
///
/// ponytail: fixed retry count + fixed delay, no exponential backoff; add
/// backoff if retries start hammering a genuinely-down server.
class _RetryOnConnectionFailureInterceptor extends Interceptor {
  _RetryOnConnectionFailureInterceptor(this._dio);

  final Dio _dio;

  static const _maxRetries = 2;
  static const _retryDelay = Duration(milliseconds: 400);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = err.requestOptions.extra['retryAttempt'] as int? ?? 0;
    if (attempt >= _maxRetries || !_isRetryable(err)) {
      handler.next(err);
      return;
    }

    await Future<void>.delayed(_retryDelay);
    final options = err.requestOptions..extra['retryAttempt'] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// A connection/handshake timeout never reached the server, so retrying is
  /// always safe. A receive timeout means the request may already have
  /// landed — only retry that for GET, which has no side effects.
  bool _isRetryable(DioException err) => switch (err.type) {
    DioExceptionType.connectionTimeout || DioExceptionType.connectionError =>
      true,
    DioExceptionType.receiveTimeout => err.requestOptions.method == 'GET',
    _ => false,
  };
}

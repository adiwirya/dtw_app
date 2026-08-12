import 'package:dio/dio.dart';
import 'package:dtw_app/core/flavor.dart';
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
          await ref.read(tenantRealtimeServiceProvider).disconnect();
          ref.read(isLoggedInProvider.notifier).state = false;
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}

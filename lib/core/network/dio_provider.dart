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
          // Best-effort cleanup — a disconnect failure must never stop
          // `handler.next(error)` below from running, or every authenticated
          // request's 401-handling breaks with it.
          try {
            await ref.read(tenantRealtimeServiceProvider).disconnect();
          } on Object catch (_) {
            // Swallowed intentionally — see comment above.
          }
          ref.read(isLoggedInProvider.notifier).state = false;
          // Reset the flavor too, not just the login flag: `App` picks its
          // router off [appFlavorProvider], so leaving it on
          // [AppFlavor.tenant] would strand an expired tenant session on
          // `tenantRouter`'s own `/login` instead of the real, shared
          // busboy `LoginScreen`. Session expiry must clear both flags
          // symmetrically — same as `AuthController.logout()`.
          ref.read(appFlavorProvider.notifier).state = AppFlavor.busboy;
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}

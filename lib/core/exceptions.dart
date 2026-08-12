import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException({required this.message, this.fieldErrors});

  final String message;
  final Map<String, List<String>>? fieldErrors;

  @override
  String toString() => 'ApiException: $message';
}

/// Back-compat name for the auth feature's original exception type — it is
/// the exact same class, so `isA<AuthException>()` and `is AuthException`
/// checks continue to work unchanged.
typedef AuthException = ApiException;

/// The user-facing Indonesian message to show for an arbitrary caught
/// [error].
///
/// Repositories already map transport failures to [ApiException] (see
/// [mapDioError]), so its [ApiException.message] is the specific, actionable
/// copy. Anything else reaching the UI is a bug rather than an expected
/// failure mode, so it degrades to the same generic fallback [mapDioError]
/// uses. Single-sourced here because every failure-capable notifier call in a
/// screen renders its SnackBar/error state through this.
String errorMessage(Object error) => error is ApiException
    ? error.message
    : 'Terjadi kesalahan. Coba lagi.';

/// Maps a [DioException] to an [ApiException] with an Indonesian
/// user-facing message. [unauthorizedMessage] lets a call site override the
/// default 401 copy (the login flow uses a login-specific message; every
/// other repository gets the generic default).
ApiException mapDioError(
  DioException error, {
  String Function(int? statusCode)? unauthorizedMessage,
}) {
  final statusCode = error.response?.statusCode;

  if (statusCode == 422) {
    final rawErrors = error.response?.data is Map
        ? (error.response?.data as Map)['errors']
        : null;
    final fieldErrors = <String, List<String>>{};
    if (rawErrors is Map) {
      rawErrors.forEach((key, value) {
        if (value is List) {
          fieldErrors[key.toString()] =
              value.map((m) => m.toString()).toList();
        }
      });
    }
    final message = fieldErrors.values.expand((m) => m).join(' ');
    return ApiException(
      message: message.isEmpty ? 'Data tidak valid.' : message,
      fieldErrors: fieldErrors.isEmpty ? null : fieldErrors,
    );
  }

  if (statusCode == 401) {
    return ApiException(
      message: unauthorizedMessage?.call(statusCode) ??
          'Sesi berakhir. Silakan masuk kembali.',
    );
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.receiveTimeout) {
    return ApiException(
      message: 'Tidak bisa terhubung ke server. Cek koneksi internet.',
    );
  }

  return ApiException(message: 'Terjadi kesalahan. Coba lagi.');
}

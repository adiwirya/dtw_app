import 'package:dio/dio.dart';
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/network/dio_provider.dart';
import 'package:dtw_app/core/storage/local_storage.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/auth/data/models/login_request.dart';
import 'package:dtw_app/features/auth/data/models/login_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  AuthRepository({required Dio dio, required LocalStorage localStorage})
      : _dio = dio,
        _localStorage = localStorage;

  final Dio _dio;
  final LocalStorage _localStorage;

  Future<void> loginWithPassword({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/login',
        data: LoginRequest.password(
          username: username,
          password: password,
        ).toJson(),
      );
      final loginResponse = LoginResponse.fromJson(response.data!);
      await _localStorage.write(authTokenStorageKey, loginResponse.accessToken);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('/v1/auth/logout');
    } on DioException {
      // Best-effort: still clear the local session even if the server call fails.
    } finally {
      await _localStorage.delete(authTokenStorageKey);
    }
  }

  AuthException _mapError(DioException error) {
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
      return AuthException(
        message: message.isEmpty ? 'Data tidak valid.' : message,
        fieldErrors: fieldErrors.isEmpty ? null : fieldErrors,
      );
    }

    if (statusCode == 401) {
      return AuthException(message: 'Username atau password salah.');
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.receiveTimeout) {
      return AuthException(
        message: 'Tidak bisa terhubung ke server. Cek koneksi internet.',
      );
    }

    return AuthException(message: 'Terjadi kesalahan. Coba lagi.');
  }
}

@riverpod
AuthRepository authRepository(Ref ref) => AuthRepository(
      dio: ref.watch(dioProvider),
      localStorage: ref.watch(localStorageProvider),
    );

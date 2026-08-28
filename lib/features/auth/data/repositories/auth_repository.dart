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

  Future<LoginResponse> loginWithPassword({
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
      final role = loginResponse.user.role;
      if (role != null) {
        await _localStorage.write(sessionRoleStorageKey, role);
      } else {
        await _localStorage.delete(sessionRoleStorageKey);
      }
      // Named to avoid shadowing this method's `username` parameter.
      final sessionUsername = loginResponse.user.username;
      if (sessionUsername != null) {
        await _localStorage.write(
          sessionUsernameStorageKey,
          sessionUsername,
        );
      } else {
        await _localStorage.delete(sessionUsernameStorageKey);
      await _localStorage.delete(sessionRoleStorageKey);
      }
      if (loginResponse.branchId != null) {
        await _localStorage.write(
          tenantBranchIdStorageKey,
          loginResponse.branchId!,
        );
      } else {
        await _localStorage.delete(tenantBranchIdStorageKey);
      }
      if (loginResponse.zoneId != null) {
        await _localStorage.write(busboyZoneIdStorageKey, loginResponse.zoneId!);
      } else {
        await _localStorage.delete(busboyZoneIdStorageKey);
      }
      return loginResponse;
    } on DioException catch (error) {
      throw mapDioError(
        error,
        unauthorizedMessage: (_) => 'Username atau password salah.',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('/v1/auth/logout');
    } on DioException {
      // Best-effort: still clear the local session even if the server call fails.
    } finally {
      await _localStorage.delete(authTokenStorageKey);
      await _localStorage.delete(sessionUsernameStorageKey);
      await _localStorage.delete(sessionRoleStorageKey);
      await _localStorage.delete(tenantBranchIdStorageKey);
      await _localStorage.delete(busboyZoneIdStorageKey);
    }
  }

}

@riverpod
AuthRepository authRepository(Ref ref) => AuthRepository(
      dio: ref.watch(dioProvider),
      localStorage: ref.watch(localStorageProvider),
    );

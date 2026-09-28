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
  AuthRepository({required this._dio, required LocalStorage localStorage})
      : _localStorage = localStorage;

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
      await _localStorage.write(sessionUserIdStorageKey, loginResponse.user.id);
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
      final name = loginResponse.user.name;
      if (name != null) {
        await _localStorage.write(sessionNameStorageKey, name);
      } else {
        await _localStorage.delete(sessionNameStorageKey);
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

  /// `POST /v1/auth/forgot-password` — always succeeds (200) regardless of
  /// whether [email] has an account, by API design (anti-enumeration): a
  /// caller must never infer or display "this email exists/doesn't exist"
  /// from the result. Only a network failure, a malformed [email] (422) or
  /// the rate limit (429, 5/min/IP) throw.
  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/v1/auth/forgot-password',
        data: {'email': email},
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// `POST /v1/auth/reset-password` — [token] is the one emailed by
  /// [forgotPassword], valid once and for 60 minutes. Success revokes every
  /// other active session for this account (server-side, not reflected
  /// here — this device isn't logged in yet at this point in the flow).
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/v1/auth/reset-password',
        data: {
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('/v1/auth/logout');
    } on DioException {
      // Best-effort: still clear the local session even if the server call fails.
    } finally {
      await _localStorage.delete(authTokenStorageKey);
      await _localStorage.delete(sessionUserIdStorageKey);
      await _localStorage.delete(sessionUsernameStorageKey);
      await _localStorage.delete(sessionNameStorageKey);
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

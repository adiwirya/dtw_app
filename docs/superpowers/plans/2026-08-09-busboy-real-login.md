# Busboy Real Login Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the Busboy role path of the existing shared `LoginScreen` to the
real Downtown CMS `/v1/auth/login` (password method) endpoint, with secure
session persistence, a reactive 401/logout redirect guard, and real logout
from the Akun screen.

**Architecture:** A plain `AuthRepository` class wraps a hardened `dioProvider`
(bearer-header + 401 interceptor) and a new `SecureLocalStorage`
(`flutter_secure_storage`-backed `LocalStorage` impl). An `AsyncNotifier`
`AuthController` exposes `login()`/`logout()` for `LoginScreen` (and, for
logout, the Akun screen) to watch via `AsyncValue`. `bootstrap()` becomes
async, seeding `isLoggedInProvider` from stored-token presence before the
first frame. Both `GoRouter`s (`appRouter`, `tenantRouter`) gain a `redirect:`
guard on `isLoggedInProvider` so session expiry actually redirects, not just
at initial launch. The Tenant role path and `TenantLoginScreen` are untouched.

**Tech Stack:** Flutter, Riverpod (`flutter_riverpod`, `riverpod_annotation` +
`riverpod_generator`), `go_router`, `dio`, `flutter_secure_storage` (new).

## Global Constraints

- Base URL is a hardcoded constant, same for both flavors:
  `https://dtw-cms.gadingemerald.com/api` — no `--dart-define` needed.
- Error strings are Indonesian and must match exactly: `"Username atau
  password salah."` (401), `"Tidak bisa terhubung ke server. Cek koneksi
  internet."` (timeout/connection error), `"Terjadi kesalahan. Coba lagi."`
  (fallback), `"Data tidak valid."` (422 fallback when no field messages).
- `AuthRepository` is a concrete class with no abstract interface — matches
  how `LocalStorage` is the only infra interface deliberately introduced in
  this codebase, and `AuthRepository` has exactly one implementation.
- Storage backend is `flutter_secure_storage` — not `shared_preferences`, not
  `get_secure_storage` (a GetX-ecosystem package; this project has zero GetX
  dependency).
- No mockito in this project (not a dependency). Test doubles are hand-rolled:
  an in-memory `LocalStorage` fake and a canned `HttpClientAdapter` for `Dio`
  — both shared via `test/support/`.
- "Ingat Saya" stays UI-only decoration — the token is always persisted on
  successful login regardless of the checkbox.
- The **Tenan** role path in `LoginScreen`, and `TenantLoginScreen` entirely,
  are out of scope — do not add any real network call there. Only the
  effective-busboy path (`_selectedRole ?? LoginRole.busboy == LoginRole.busboy`)
  gets wired.
- Generated files (`*.g.dart`) are committed to git in this repo (verified via
  `git ls-files` — not gitignored) — include them in any commits.
- **Per this repo's own established convention** (`.ftk/execute-progress.md`:
  "Mode: no-commit, no-push") and the user's standing instruction for this
  session: do **not** run `git commit` during execution unless the user
  explicitly asks for it at execution time. Each task's "Commit" step below
  is written per the planning template as a natural checkpoint boundary —
  treat it as "stage/verify here", not as authorization to actually commit.
- Source spec: `docs/superpowers/specs/2026-08-09-busboy-real-login-design.md`.

---

### Task 1: Auth models + `AuthException`

**Files:**
- Create: `lib/core/exceptions.dart`
- Create: `lib/features/auth/data/models/login_request.dart`
- Create: `lib/features/auth/data/models/login_response.dart`
- Test: `test/features/auth/data/models/login_response_test.dart`

**Interfaces:**
- Produces: `LoginRequest.password({required String username, required
  String password})` → `.toJson()`; `LoginResponse.fromJson(Map<String,
  dynamic> json)` → `{accessToken, user}`; `AuthUser {id, username}`;
  `AuthException {message, fieldErrors}` implementing `Exception`.

- [ ] **Step 1: Write the failing test for `LoginResponse.fromJson`**

```dart
// test/features/auth/data/models/login_response_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dtw_app/features/auth/data/models/login_response.dart';

void main() {
  test('LoginResponse.fromJson parses the envelope data field', () {
    final json = {
      'meta': {'success': true, 'message': 'Success', 'code': 200, 'trace_id': 'abc'},
      'data': {
        'access_token': 'tok_123',
        'user': {'id': 'u1', 'username': 'budi'},
        'abilities': [],
        'scopes': [],
      },
    };

    final result = LoginResponse.fromJson(json);

    expect(result.accessToken, 'tok_123');
    expect(result.user.id, 'u1');
    expect(result.user.username, 'budi');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/data/models/login_response_test.dart`
Expected: FAIL — `Error: Not found: 'package:dtw_app/features/auth/data/models/login_response.dart'` (file doesn't exist yet).

- [ ] **Step 3: Implement `LoginResponse` and `AuthUser`**

```dart
// lib/features/auth/data/models/login_response.dart
class AuthUser {
  const AuthUser({required this.id, this.username});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      username: json['username'] as String?,
    );
  }

  final String id;
  final String? username;
}

class LoginResponse {
  const LoginResponse({required this.accessToken, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return LoginResponse(
      accessToken: data['access_token'] as String,
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  final String accessToken;
  final AuthUser user;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/auth/data/models/login_response_test.dart`
Expected: PASS

- [ ] **Step 5: Implement `LoginRequest` (no test — trivial map literal)**

```dart
// lib/features/auth/data/models/login_request.dart
class LoginRequest {
  const LoginRequest._({required this.method, this.username, this.password});

  factory LoginRequest.password({
    required String username,
    required String password,
  }) {
    return LoginRequest._(method: 'password', username: username, password: password);
  }

  final String method;
  final String? username;
  final String? password;

  Map<String, dynamic> toJson() => {
        'method': method,
        if (username != null) 'username': username,
        if (password != null) 'password': password,
      };
}
```

- [ ] **Step 6: Implement `AuthException` (no test — trivial data class)**

```dart
// lib/core/exceptions.dart
class AuthException implements Exception {
  AuthException({required this.message, this.fieldErrors});

  final String message;
  final Map<String, List<String>>? fieldErrors;

  @override
  String toString() => 'AuthException: $message';
}
```

- [ ] **Step 7: Run the full test suite to confirm nothing else broke**

Run: `flutter test`
Expected: All PASS (existing suite + the new `login_response_test.dart`).

- [ ] **Step 8: Commit**

```bash
git add lib/core/exceptions.dart lib/features/auth/data/models/ test/features/auth/data/models/
git commit -m "feat(auth): add LoginRequest/LoginResponse models and AuthException"
```

---

### Task 2: `SecureLocalStorage` + `localStorageProvider`

**Files:**
- Modify: `pubspec.yaml` (add `flutter_secure_storage`)
- Create: `lib/core/storage/secure_local_storage.dart`

**Interfaces:**
- Consumes: `LocalStorage` (`lib/core/storage/local_storage.dart`, existing,
  unchanged: `Future<String?> read(String key)`, `Future<void> write(String
  key, String value)`, `Future<void> delete(String key)`).
- Produces: `const authTokenStorageKey = 'auth_token'`; `class
  SecureLocalStorage implements LocalStorage`; `@riverpod LocalStorage
  localStorage(Ref ref)` (provider name: `localStorageProvider`).

- [ ] **Step 1: Add the dependency**

Run: `flutter pub add flutter_secure_storage`
Expected: `pubspec.yaml`'s `dependencies` gains a `flutter_secure_storage:
^<resolved version>` line.

- [ ] **Step 2: Implement `SecureLocalStorage` and its provider**

```dart
// lib/core/storage/secure_local_storage.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'local_storage.dart';

part 'secure_local_storage.g.dart';

/// Key the access token is stored under, shared between [SecureLocalStorage]
/// consumers: the login/logout flow (`AuthRepository`) and the request/error
/// interceptors in `dioProvider`.
const authTokenStorageKey = 'auth_token';

/// [LocalStorage] backed by the platform Keychain (iOS) / EncryptedShared
/// Preferences+Keystore (Android) via `flutter_secure_storage`.
class SecureLocalStorage implements LocalStorage {
  const SecureLocalStorage({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

@riverpod
LocalStorage localStorage(Ref ref) => const SecureLocalStorage();
```

No dedicated unit test here: `SecureLocalStorage` is a 3-method pass-through
to `flutter_secure_storage`'s platform channel, which has no in-memory test
mode — it's exercised indirectly by every test in later tasks that overrides
`localStorageProvider` with the `FakeLocalStorage` test double (Task 3+).

- [ ] **Step 3: Generate the provider code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/core/storage/secure_local_storage.g.dart` is created,
exporting `localStorageProvider`.

- [ ] **Step 4: Verify with static analysis**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/storage/secure_local_storage.dart lib/core/storage/secure_local_storage.g.dart
git commit -m "feat(auth): add SecureLocalStorage (flutter_secure_storage-backed LocalStorage)"
```

---

### Task 3: Harden `dioProvider` — bearer header + 401 interceptor

**Files:**
- Modify: `lib/core/network/dio_provider.dart`
- Create: `test/support/fake_local_storage.dart`
- Create: `test/support/canned_dio.dart`
- Test: `test/core/network/dio_provider_test.dart`

**Interfaces:**
- Consumes: `localStorageProvider`, `authTokenStorageKey` (Task 2);
  `isLoggedInProvider` (`lib/core/flavor.dart`, existing).
- Produces: `dioProvider` (unchanged provider name/type — `Dio`), now with a
  hardcoded base URL and the interceptor described below. Also produces two
  test doubles reused by every later task's tests: `class FakeLocalStorage
  implements LocalStorage` (`test/support/fake_local_storage.dart`) and
  `class CannedAdapter implements HttpClientAdapter` + `Dio cannedDio(int
  statusCode, Object? body, {String baseUrl})` (`test/support/canned_dio.dart`).

- [ ] **Step 1: Create the shared test doubles**

```dart
// test/support/fake_local_storage.dart
import 'package:dtw_app/core/storage/local_storage.dart';

/// In-memory [LocalStorage] test double — no platform channel involved.
class FakeLocalStorage implements LocalStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
```

```dart
// test/support/canned_dio.dart
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

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
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
```

- [ ] **Step 2: Write the failing tests for the interceptor**

```dart
// test/core/network/dio_provider_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/network/dio_provider.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';

import '../../support/canned_dio.dart';
import '../../support/fake_local_storage.dart';

void main() {
  test('attaches the stored token as a Bearer header', () async {
    final storage = FakeLocalStorage();
    await storage.write(authTokenStorageKey, 'tok_abc');
    final container = ProviderContainer(
      overrides: [localStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    final dio = container.read(dioProvider);
    final adapter = CannedAdapter(200, {'ok': true});
    dio.httpClientAdapter = adapter;

    await dio.get<void>('/v1/whatever');

    expect(adapter.lastRequest?.headers['Authorization'], 'Bearer tok_abc');
  });

  test('401 clears the token and flips isLoggedInProvider to false', () async {
    final storage = FakeLocalStorage();
    await storage.write(authTokenStorageKey, 'tok_abc');
    final container = ProviderContainer(
      overrides: [localStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    container.read(isLoggedInProvider.notifier).state = true;

    final dio = container.read(dioProvider);
    dio.httpClientAdapter = CannedAdapter(401, {'errors': null});

    try {
      await dio.get<void>('/v1/whatever');
    } on DioException catch (_) {
      // Expected: the canned adapter returns 401, which Dio surfaces as an error.
    }

    expect(await storage.read(authTokenStorageKey), isNull);
    expect(container.read(isLoggedInProvider), isFalse);
  });
}
```

(Discard the first, placeholder-containing snippet above it — it was a
typo left in during drafting; only the second, complete version is the
actual step. The file must contain exactly one `void main()`.)

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/core/network/dio_provider_test.dart`
Expected: FAIL — compile error, `localStorageProvider` / `authTokenStorageKey` not found (Task 2 exists already, so this should actually be a runtime assertion failure instead: the Bearer header is missing because `dioProvider` doesn't attach it yet, and `isLoggedInProvider` doesn't get flipped on 401). Either failure mode confirms the interceptor isn't wired yet.

- [ ] **Step 4: Update `dioProvider`**

```dart
// lib/core/network/dio_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../flavor.dart';
import '../storage/secure_local_storage.dart';

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
        final token = await ref.read(localStorageProvider).read(authTokenStorageKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await ref.read(localStorageProvider).delete(authTokenStorageKey);
          ref.read(isLoggedInProvider.notifier).state = false;
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}
```

- [ ] **Step 5: Regenerate and run tests to verify they pass**

Run: `dart run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/core/network/dio_provider_test.dart`
Expected: Both tests PASS.

- [ ] **Step 6: Run the full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: All PASS, no analyzer errors. (`dioProvider`'s consumers —
`akun_provider.dart` etc. — don't call it today, so no ripple breakage
expected; if any surfaces, it means a mock data provider now transitively
touches `dio`, which would be a real regression to fix, not to suppress.)

- [ ] **Step 7: Commit**

```bash
git add lib/core/network/dio_provider.dart lib/core/network/dio_provider.g.dart test/support/ test/core/network/dio_provider_test.dart
git commit -m "feat(auth): attach bearer token and auto-clear session on 401"
```

---

### Task 4: `AuthRepository`

**Files:**
- Create: `lib/features/auth/data/repositories/auth_repository.dart`
- Test: `test/features/auth/data/repositories/auth_repository_test.dart`

**Interfaces:**
- Consumes: `dioProvider` (Task 3), `localStorageProvider`,
  `authTokenStorageKey` (Task 2), `LoginRequest.password`, `LoginResponse`
  (Task 1), `AuthException` (Task 1), `FakeLocalStorage`, `cannedDio` (Task 3).
- Produces: `class AuthRepository { AuthRepository({required Dio dio,
  required LocalStorage localStorage}); Future<void> loginWithPassword({
  required String username, required String password}); Future<void>
  logout(); }`; `@riverpod AuthRepository authRepository(Ref ref)`
  (provider name: `authRepositoryProvider`).

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/auth/data/repositories/auth_repository_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/auth/data/repositories/auth_repository.dart';

import '../../../../support/canned_dio.dart';
import '../../../../support/fake_local_storage.dart';

void main() {
  test('loginWithPassword stores the access token on success', () async {
    final storage = FakeLocalStorage();
    final repository = AuthRepository(
      dio: cannedDio(200, {
        'meta': {'success': true, 'message': 'Success', 'code': 200, 'trace_id': 'abc'},
        'data': {
          'access_token': 'tok_123',
          'user': {'id': 'u1', 'username': 'budi'},
        },
      }),
      localStorage: storage,
    );

    await repository.loginWithPassword(username: 'budi', password: 'secret');

    expect(storage.values[authTokenStorageKey], 'tok_123');
  });

  test('loginWithPassword throws AuthException with fieldErrors on 422', () async {
    final storage = FakeLocalStorage();
    final repository = AuthRepository(
      dio: cannedDio(422, {
        'meta': {'success': false, 'message': 'Validation', 'code': 422, 'trace_id': 'abc'},
        'errors': {
          'password': ['Password wajib diisi.'],
        },
      }),
      localStorage: storage,
    );

    await expectLater(
      repository.loginWithPassword(username: 'budi', password: ''),
      throwsA(
        isA<AuthException>()
            .having((e) => e.fieldErrors, 'fieldErrors', {'password': ['Password wajib diisi.']})
            .having((e) => e.message, 'message', 'Password wajib diisi.'),
      ),
    );
  });

  test('loginWithPassword throws a generic message on 401', () async {
    final storage = FakeLocalStorage();
    final repository = AuthRepository(
      dio: cannedDio(401, {
        'meta': {'success': false, 'message': 'Unauthorized', 'code': 401, 'trace_id': 'abc'},
        'errors': null,
      }),
      localStorage: storage,
    );

    await expectLater(
      repository.loginWithPassword(username: 'budi', password: 'wrong'),
      throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Username atau password salah.')),
    );
  });

  test('loginWithPassword throws a connectivity message on connection error', () async {
    final storage = FakeLocalStorage();
    final repository = AuthRepository(
      dio: cannedDio(500, {'meta': {'success': false, 'message': 'Error', 'code': 500, 'trace_id': 'abc'}}),
      localStorage: storage,
    );

    // 500 falls into the generic branch — connection-error is exercised via
    // the DioExceptionType directly since CannedAdapter always completes
    // with a response (it can't simulate a socket-level failure).
    await expectLater(
      repository.loginWithPassword(username: 'budi', password: 'secret'),
      throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Terjadi kesalahan. Coba lagi.')),
    );
  });

  test('logout clears the local session even if the API call fails', () async {
    final storage = FakeLocalStorage()..values[authTokenStorageKey] = 'tok_123';
    final repository = AuthRepository(
      dio: cannedDio(500, {'meta': {'success': false, 'message': 'Error', 'code': 500, 'trace_id': 'abc'}}),
      localStorage: storage,
    );

    await repository.logout();

    expect(storage.values.containsKey(authTokenStorageKey), isFalse);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/auth/data/repositories/auth_repository_test.dart`
Expected: FAIL — `Error: Not found: 'package:dtw_app/features/auth/data/repositories/auth_repository.dart'`.

- [ ] **Step 3: Implement `AuthRepository`**

```dart
// lib/features/auth/data/repositories/auth_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/exceptions.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_local_storage.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

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
        data: LoginRequest.password(username: username, password: password).toJson(),
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
      final rawErrors = error.response?.data is Map ? (error.response?.data as Map)['errors'] : null;
      final fieldErrors = <String, List<String>>{};
      if (rawErrors is Map) {
        rawErrors.forEach((key, value) {
          if (value is List) {
            fieldErrors[key.toString()] = value.map((m) => m.toString()).toList();
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
      return AuthException(message: 'Tidak bisa terhubung ke server. Cek koneksi internet.');
    }

    return AuthException(message: 'Terjadi kesalahan. Coba lagi.');
  }
}

@riverpod
AuthRepository authRepository(Ref ref) => AuthRepository(
      dio: ref.watch(dioProvider),
      localStorage: ref.watch(localStorageProvider),
    );
```

- [ ] **Step 4: Regenerate and run tests to verify they pass**

Run: `dart run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/features/auth/data/repositories/auth_repository_test.dart`
Expected: All 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/data/repositories/ test/features/auth/data/repositories/
git commit -m "feat(auth): add AuthRepository with password login and error mapping"
```

---

### Task 5: `AuthController`

**Files:**
- Create: `lib/features/auth/presentation/providers/auth_controller.dart`
- Test: `test/features/auth/presentation/providers/auth_controller_test.dart`

**Interfaces:**
- Consumes: `authRepositoryProvider` (Task 4), `isLoggedInProvider`,
  `appFlavorProvider`, `AppFlavor` (`lib/core/flavor.dart`, existing),
  `AuthException` (Task 1), `FakeLocalStorage`, `cannedDio` (Task 3).
- Produces: `@riverpod class AuthController extends _$AuthController`
  (provider name: `authControllerProvider`, type
  `AsyncNotifierProvider<AuthController, void>`) — `Future<void>
  login({required String username, required String password})`,
  `Future<void> logout()`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/auth/presentation/providers/auth_controller_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/auth/data/repositories/auth_repository.dart';
import 'package:dtw_app/features/auth/presentation/providers/auth_controller.dart';

import '../../../../support/canned_dio.dart';
import '../../../../support/fake_local_storage.dart';

AuthRepository _repositoryReturning(int statusCode, Object? body, FakeLocalStorage storage) {
  return AuthRepository(dio: cannedDio(statusCode, body), localStorage: storage);
}

void main() {
  test('login sets isLoggedInProvider and appFlavorProvider on success', () async {
    final storage = FakeLocalStorage();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _repositoryReturning(200, {
            'meta': {'success': true, 'message': 'Success', 'code': 200, 'trace_id': 'abc'},
            'data': {
              'access_token': 'tok_123',
              'user': {'id': 'u1', 'username': 'budi'},
            },
          }, storage),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).login(username: 'budi', password: 'secret');

    expect(container.read(isLoggedInProvider), isTrue);
    expect(container.read(appFlavorProvider), AppFlavor.busboy);
    expect(container.read(authControllerProvider).hasError, isFalse);
  });

  test('login sets an AsyncError with the mapped AuthException on 401', () async {
    final storage = FakeLocalStorage();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _repositoryReturning(401, {
            'meta': {'success': false, 'message': 'Unauthorized', 'code': 401, 'trace_id': 'abc'},
            'errors': null,
          }, storage),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).login(username: 'budi', password: 'wrong');

    final state = container.read(authControllerProvider);
    expect(state.hasError, isTrue);
    expect((state.error! as AuthException).message, 'Username atau password salah.');
    expect(container.read(isLoggedInProvider), isFalse);
  });

  test('logout clears isLoggedInProvider', () async {
    final storage = FakeLocalStorage()..values[authTokenStorageKey] = 'tok_123';
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _repositoryReturning(200, {
            'meta': {'success': true, 'message': 'Success', 'code': 200, 'trace_id': 'abc'},
          }, storage),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(isLoggedInProvider.notifier).state = true;

    await container.read(authControllerProvider.notifier).logout();

    expect(container.read(isLoggedInProvider), isFalse);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/auth/presentation/providers/auth_controller_test.dart`
Expected: FAIL — `Error: Not found: 'package:dtw_app/features/auth/presentation/providers/auth_controller.dart'`.

- [ ] **Step 3: Implement `AuthController`**

```dart
// lib/features/auth/presentation/providers/auth_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/flavor.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  Future<void> build() async {}

  Future<void> login({required String username, required String password}) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).loginWithPassword(
            username: username,
            password: password,
          );
      ref.read(isLoggedInProvider.notifier).state = true;
      ref.read(appFlavorProvider.notifier).state = AppFlavor.busboy;
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.read(isLoggedInProvider.notifier).state = false;
  }
}
```

- [ ] **Step 4: Regenerate and run tests to verify they pass**

Run: `dart run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/features/auth/presentation/providers/auth_controller_test.dart`
Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/providers/auth_controller.dart lib/features/auth/presentation/providers/auth_controller.g.dart test/features/auth/presentation/providers/
git commit -m "feat(auth): add AuthController exposing login/logout as AsyncValue"
```

---

### Task 6: Wire `LoginScreen`'s Busboy path to `AuthController`

**Files:**
- Modify: `lib/features/auth/presentation/screens/login_screen.dart`
- Modify: `test/features/auth/presentation/login_screen_test.dart`

**Interfaces:**
- Consumes: `authControllerProvider` (Task 5), `AuthException` (Task 1),
  `AppColors.dangerRed` (`lib/core/theme/app_theme.dart`, existing).
- Produces: no new public API — `LoginScreen`'s visible behavior on the
  Busboy path changes from "always navigate" to "validate → call API →
  navigate on success / show error on failure".

- [ ] **Step 1: Update the failing/changed tests first**

Two existing tests in `test/features/auth/presentation/login_screen_test.dart`
currently tap "Masuk" with empty fields and expect immediate navigation —
that behavior is going away for the Busboy path.

First, add these two imports to the file's existing import list (all other
existing imports — `dtw_app/app.dart`, `primary_button.dart`,
`login_screen.dart`, `role_card.dart`, `material.dart`,
`flutter_riverpod/flutter_riverpod.dart`, `flutter_test/flutter_test.dart`,
`go_router/go_router.dart` — stay exactly as they are):

```dart
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/features/auth/data/repositories/auth_repository.dart';

import '../../../support/canned_dio.dart';
import '../../../support/fake_local_storage.dart';
```

Then replace the file's entire `group('Masuk picks the flavor for the
selected role (single shared entry)')` block with the version below (the
`_router()`/`_pumpRouter()` helpers and the first three `testWidgets` above
this group are untouched):

```dart
  group('Masuk picks the flavor for the selected role (single shared entry)',
      () {
    Future<ProviderContainer> pumpApp(
      WidgetTester tester, {
      required int statusCode,
      required Object? body,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final storage = FakeLocalStorage();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepository(dio: cannedDio(statusCode, body), localStorage: storage),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const App()),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets(
        'no role selected defaults to busboy, calls the API, and lands on its Order tab',
        (tester) async {
      await pumpApp(
        tester,
        statusCode: 200,
        body: {
          'meta': {'success': true, 'message': 'Success', 'code': 200, 'trace_id': 'abc'},
          'data': {
            'access_token': 'tok_123',
            'user': {'id': 'u1', 'username': 'budi'},
          },
        },
      );

      await tester.enterText(find.widgetWithText(AppInput, 'Username'), 'budi');
      await tester.enterText(find.widgetWithText(AppInput, 'Password'), 'secret');
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // The real busboy Order home renders its Ambil/Antar/Selesai sub-tabs.
      expect(find.text('Ambil'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      // Bottom nav confirms we're in the busboy shell, not the tenant one.
      expect(find.text('Performa'), findsOneWidget);
    });

    testWidgets('shows the mapped error message on a failed busboy login',
        (tester) async {
      await pumpApp(
        tester,
        statusCode: 401,
        body: {
          'meta': {'success': false, 'message': 'Unauthorized', 'code': 401, 'trace_id': 'abc'},
          'errors': null,
        },
      );

      await tester.enterText(find.widgetWithText(AppInput, 'Username'), 'budi');
      await tester.enterText(find.widgetWithText(AppInput, 'Password'), 'wrong');
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('Username atau password salah.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('picking Tenan switches the whole app to the tenant shell',
        (tester) async {
      await pumpApp(tester, statusCode: 200, body: {'meta': {'success': true, 'message': 'ok', 'code': 200, 'trace_id': 'x'}});

      // Step 1 -> step 2 (always pre-selects Busboy); explicitly pick Tenan.
      await tester.tap(find.text('Tenan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tenan'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // The tenant Order home renders directly — no second login screen, no
      // API call for this still-stubbed path.
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('KFC\nFried Chicken'), findsOneWidget);
      // Tenant bottom nav labels confirm the flavor switch.
      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Laporan'), findsOneWidget);
    });
  });
```

Also add the two new imports (`AppInput`, already used elsewhere in this
file's screen — confirm `import 'package:dtw_app/core/widgets/app_input.dart';`
is present; add it if not) needed by `find.widgetWithText(AppInput, ...)`.

- [ ] **Step 2: Run the changed tests to verify they fail**

Run: `flutter test test/features/auth/presentation/login_screen_test.dart`
Expected: FAIL — the first new test times out/fails to navigate (Masuk still
navigates unconditionally with no validation or API call yet); the second
new test fails because no error text is ever shown.

- [ ] **Step 3: Update `LoginScreen`**

In `lib/features/auth/presentation/screens/login_screen.dart`:

Add imports (alongside the existing ones):
```dart
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/features/auth/presentation/providers/auth_controller.dart';
```

Add a field next to the existing `_selectedRole`/`_rememberMe` fields:
```dart
  String? _validationMessage;
```

Replace the existing `_onMasuk` method:
```dart
  void _onMasuk() {
    // TODO(open-question): auth is out of scope (Open Question 1) — "Masuk"
    // only picks the flavor matching the selected role; no credential
    // validation is performed.
    ref.read(isLoggedInProvider.notifier).state = true;
    ref.read(appFlavorProvider.notifier).state =
        (_selectedRole ?? LoginRole.busboy) == LoginRole.tenan
            ? AppFlavor.tenant
            : AppFlavor.busboy;
  }
```
with:
```dart
  Future<void> _onMasuk() async {
    final effectiveRole = _selectedRole ?? LoginRole.busboy;
    if (effectiveRole == LoginRole.tenan) {
      // Tenant login is card/NFC-based and out of scope here — keep the
      // existing mock flavor switch until that spec lands.
      ref.read(isLoggedInProvider.notifier).state = true;
      ref.read(appFlavorProvider.notifier).state = AppFlavor.tenant;
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _validationMessage = 'Username dan password wajib diisi.');
      return;
    }
    setState(() => _validationMessage = null);

    await ref.read(authControllerProvider.notifier).login(
          username: username,
          password: password,
        );
  }
```

Update `build()` to watch the controller and thread it into the form. Replace:
```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
```
with:
```dart
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    return Scaffold(
```
and replace the `_buildForm(),` call inside the body's `Column` with
`_buildForm(authState),`.

Replace the `_buildForm()` method signature and body:
```dart
  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(
            controller: _usernameController,
            label: 'Username',
            hintText: 'Masukkan username',
            leadingIcon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          AppInput(
            controller: _passwordController,
            label: 'Password',
            hintText: 'Masukkan password',
            leadingIcon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          _buildRememberRow(),
          const SizedBox(height: 40),
          PrimaryButton(label: 'Masuk', onPressed: _onMasuk),
        ],
      ),
    );
  }
```
with:
```dart
  Widget _buildForm(AsyncValue<void> authState) {
    final error = authState.error;
    final errorMessage = _validationMessage ??
        (error == null ? null : (error is AuthException ? error.message : 'Terjadi kesalahan. Coba lagi.'));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(
            controller: _usernameController,
            label: 'Username',
            hintText: 'Masukkan username',
            leadingIcon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          AppInput(
            controller: _passwordController,
            label: 'Password',
            hintText: 'Masukkan password',
            leadingIcon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          _buildRememberRow(),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage,
              style: const TextStyle(color: AppColors.dangerRed, fontSize: 14),
            ),
          ],
          const SizedBox(height: 40),
          PrimaryButton(
            label: 'Masuk',
            onPressed: authState.isLoading ? null : _onMasuk,
          ),
        ],
      ),
    );
  }
```

Need `import 'package:flutter_riverpod/flutter_riverpod.dart';` for
`AsyncValue` — confirm it's already imported (it is, for `ConsumerStatefulWidget`).

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/auth/presentation/login_screen_test.dart`
Expected: All 6 tests PASS (3 unchanged + 3 in the updated group).

- [ ] **Step 5: Run the golden tests to confirm no visual regression**

Run: `flutter test test/features/auth/presentation/login_screen_golden_test.dart`
Expected: PASS unchanged — the error `Text` only renders when
`errorMessage != null`, which is not the case in either golden's default
(no-error, not-loading) state.

- [ ] **Step 6: Run the full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: All PASS, no analyzer errors.

- [ ] **Step 7: Commit**

```bash
git add lib/features/auth/presentation/screens/login_screen.dart test/features/auth/presentation/login_screen_test.dart
git commit -m "feat(auth): wire LoginScreen's busboy path to real password login"
```

---

### Task 7: Reactive `redirect:` guard on both routers

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/core/router/tenant_router.dart`
- Test: `test/core/router/app_router_redirect_test.dart`

**Interfaces:**
- Consumes: `isLoggedInProvider` (existing), `AppRoutes.loginPath`/
  `AppRoutes.orderPath`, `TenantRoutes.loginPath`/`TenantRoutes.orderPath`
  (existing constants, unchanged).
- Produces: no new public API — `appRouterProvider`/`tenantRouterProvider`
  now redirect reactively instead of only setting `initialLocation` once.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/router/app_router_redirect_test.dart
import 'package:dtw_app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dtw_app/core/flavor.dart';

void main() {
  testWidgets(
      'a mid-session logout (e.g. from a 401) redirects to the login screen',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(isLoggedInProvider.notifier).state = true;

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await tester.pumpAndSettle();

    // Starts logged in, landed on the busboy Order tab.
    expect(find.text('Ambil'), findsOneWidget);

    // Simulate the dio 401 interceptor clearing the session.
    container.read(isLoggedInProvider.notifier).state = false;
    await tester.pumpAndSettle();

    expect(find.text('Masuk Sebagai'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/router/app_router_redirect_test.dart`
Expected: FAIL — still on the Order tab after `isLoggedInProvider` flips to
`false` (no guard exists yet to react to it).

- [ ] **Step 3: Add the guard to `app_router.dart`**

In `lib/core/router/app_router.dart`, replace:
```dart
@riverpod
GoRouter appRouter(Ref ref) => GoRouter(
      // Post-login lands on the Order tab (see login-tenantt →
      // menu-order-baru in the prototype flow). [isLoggedInProvider] is what
      // lets the shared login screen switch flavor and land straight on this
      // router's Order tab instead of its own login screen.
      initialLocation: ref.watch(isLoggedInProvider)
          ? AppRoutes.orderPath
          : AppRoutes.loginPath,
      routes: [
```
with:
```dart
@riverpod
GoRouter appRouter(Ref ref) {
  final loggedIn = ref.watch(isLoggedInProvider);
  return GoRouter(
    // Post-login lands on the Order tab (see login-tenantt →
    // menu-order-baru in the prototype flow). [isLoggedInProvider] is what
    // lets the shared login screen switch flavor and land straight on this
    // router's Order tab instead of its own login screen.
    initialLocation: loggedIn ? AppRoutes.orderPath : AppRoutes.loginPath,
    // Session expiry (401, via dioProvider's interceptor) clears
    // isLoggedInProvider mid-use; this guard makes that redirect to /login
    // on the next navigation, not only at the router's initial construction.
    redirect: (context, state) {
      final onLogin = state.matchedLocation == AppRoutes.loginPath ||
          state.matchedLocation.startsWith('${AppRoutes.loginPath}/');
      if (!loggedIn && !onLogin) return AppRoutes.loginPath;
      if (loggedIn && onLogin) return AppRoutes.orderPath;
      return null;
    },
    routes: [
```
Then, at the very end of the file, replace the final closing:
```dart
    );
```
(the line that closes the `GoRouter(` call — the last non-blank line of the
file) with:
```dart
    );
}
```
Every route definition between `routes: [` and this closing line stays
byte-for-byte unchanged.

- [ ] **Step 4: Add the matching guard to `tenant_router.dart`**

In `lib/core/router/tenant_router.dart`, replace:
```dart
@riverpod
GoRouter tenantRouter(Ref ref) => GoRouter(
      // Post-login lands on the Order tab (see login-tenantt →
      // menu-order-baru in the tenant prototype flow). [isLoggedInProvider] is
      // what lets the shared login screen switch flavor and land straight on
      // this router's Order tab instead of its own login screen.
      initialLocation: ref.watch(isLoggedInProvider)
          ? TenantRoutes.orderPath
          : TenantRoutes.loginPath,
      routes: [
```
with:
```dart
@riverpod
GoRouter tenantRouter(Ref ref) {
  final loggedIn = ref.watch(isLoggedInProvider);
  return GoRouter(
    // Post-login lands on the Order tab (see login-tenantt →
    // menu-order-baru in the tenant prototype flow). [isLoggedInProvider] is
    // what lets the shared login screen switch flavor and land straight on
    // this router's Order tab instead of its own login screen.
    initialLocation: loggedIn ? TenantRoutes.orderPath : TenantRoutes.loginPath,
    // Session expiry (401, via dioProvider's interceptor) clears
    // isLoggedInProvider mid-use; this guard makes that redirect to /login
    // on the next navigation, not only at the router's initial construction.
    redirect: (context, state) {
      final onLogin = state.matchedLocation == TenantRoutes.loginPath ||
          state.matchedLocation.startsWith('${TenantRoutes.loginPath}/');
      if (!loggedIn && !onLogin) return TenantRoutes.loginPath;
      if (loggedIn && onLogin) return TenantRoutes.orderPath;
      return null;
    },
    routes: [
```
and likewise change the file's final closing `);` to `);\n}` (same pattern
as Task 7 Step 3), leaving every route definition in between untouched.

- [ ] **Step 5: Reformat and regenerate**

Run: `dart format lib/core/router/app_router.dart lib/core/router/tenant_router.dart`
Expected: re-indents the routes array under the new block-function body
(purely cosmetic — no behavior change).

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `app_router.g.dart` / `tenant_router.g.dart` regenerate cleanly.

- [ ] **Step 6: Run the test to verify it passes**

Run: `flutter test test/core/router/app_router_redirect_test.dart`
Expected: PASS.

- [ ] **Step 7: Run the full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: All PASS, no analyzer errors — in particular, every existing
router/screen test that navigates while "logged in" or exercises `/login`
directly should be unaffected, since the guard's two branches only fire on
the *mismatched* combinations (logged-out-but-not-on-login,
logged-in-but-on-login).

- [ ] **Step 8: Commit**

```bash
git add lib/core/router/app_router.dart lib/core/router/app_router.g.dart lib/core/router/tenant_router.dart lib/core/router/tenant_router.g.dart test/core/router/
git commit -m "feat(auth): add reactive redirect guard so session expiry redirects to login"
```

---

### Task 8: Async `bootstrap()` — session restore before first frame

**Files:**
- Modify: `lib/bootstrap.dart`

**Interfaces:**
- Consumes: `SecureLocalStorage`, `authTokenStorageKey`, `localStorageProvider`
  (Task 2), `isLoggedInProvider` (existing).
- Produces: `bootstrap` becomes `Future<void> bootstrap({List<Override>
  overrides})` (was `void bootstrap(...)`) — same name/parameter shape,
  now async.

- [ ] **Step 1: Update `bootstrap()`**

```dart
// lib/bootstrap.dart
import 'package:dtw_app/app.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Boots the app. [overrides] lets an entrypoint reconfigure the ProviderScope
/// without changing `App` — `main_tenant.dart` passes a flavor override to
/// render the tenant router. The busboy entrypoints call `bootstrap()` with no
/// overrides and behave exactly as before, aside from the async session
/// restore below.
Future<void> bootstrap({List<Override> overrides = const []}) async {
  WidgetsFlutterBinding.ensureInitialized();

  const storage = SecureLocalStorage();
  final token = await storage.read(authTokenStorageKey);

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        isLoggedInProvider.overrideWith((ref) => token != null && token.isNotEmpty),
        ...overrides,
      ],
      child: const App(),
    ),
  );
}
```

No entrypoint changes needed: `lib/main_dev.dart`, `lib/main_prod.dart`, and
`lib/main_tenant.dart` all call `bootstrap()` as `void main() =>
bootstrap();` (or with `overrides:` for tenant) — a `void`-bodied
arrow function discarding a `Future<void>` is valid Dart (the same pattern
`void main() => runApp(...)` already relies on), so none of the three files
need to change.

- [ ] **Step 2: Verify with static analysis**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 3: Run the full test suite**

Run: `flutter test`
Expected: All PASS — no test calls `bootstrap()` directly (they all build
`App()`/routers under their own `ProviderScope`/`ProviderContainer`), so
this change has no test-visible surface on its own; it's covered by the
existing `test/app_test.dart` smoke test still passing.

- [ ] **Step 4: Manual verification (not automatable — requires a real device with the real API)**

Run: `flutter run -t lib/main_dev.dart` (or whichever entrypoint you use for
local development)
Expected: App opens directly on the login screen (no stored token yet).
Logging in with a valid CMS username/password, then fully closing and
reopening the app, should land directly on the Order tab — no login screen —
confirming the token round-trips through `flutter_secure_storage` across
process restarts.

- [ ] **Step 5: Commit**

```bash
git add lib/bootstrap.dart
git commit -m "feat(auth): restore session from secure storage before first frame"
```

---

### Task 9: Wire Akun screen's "Keluar" to real logout

**Files:**
- Modify: `lib/features/akun/presentation/screens/akun_screen.dart`
- Modify: `test/features/akun/presentation/akun_screen_test.dart`

**Interfaces:**
- Consumes: `authControllerProvider` (Task 5), `authRepositoryProvider`
  (Task 4), `FakeLocalStorage`, `cannedDio` (Task 3).
- Produces: no new public API — the existing `logoutItem` tap now performs
  a real logout instead of being a no-op.

- [ ] **Step 1: Write the failing test**

Keep the existing two tests and the `_testRouter()`/`_pump()` helpers in
`test/features/akun/presentation/akun_screen_test.dart` exactly as they are.

First, add these imports to the file's existing import list:

```dart
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/auth/data/repositories/auth_repository.dart';

import '../../../support/canned_dio.dart';
import '../../../support/fake_local_storage.dart';
```

Then add this `testWidgets` inside `void main()`, after the existing two:

```dart
  testWidgets('tapping Keluar logs out and clears isLoggedInProvider',
      (tester) async {
    final storage = FakeLocalStorage()..values[authTokenStorageKey] = 'tok_123';
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          AuthRepository(
            dio: cannedDio(200, {
              'meta': {'success': true, 'message': 'Success', 'code': 200, 'trace_id': 'abc'},
            }),
            localStorage: storage,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(isLoggedInProvider.notifier).state = true;

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: _testRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();

    expect(container.read(isLoggedInProvider), isFalse);
  });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/akun/presentation/akun_screen_test.dart`
Expected: FAIL — `isLoggedInProvider` is still `true` after the tap (`
_onLogout` is currently a no-op).

- [ ] **Step 3: Wire `AkunScreen`**

In `lib/features/akun/presentation/screens/akun_screen.dart`, add the import:
```dart
import 'package:dtw_app/features/auth/presentation/providers/auth_controller.dart';
```

Replace:
```dart
  void _onLogout(BuildContext context) {
    // TODO(open-question): logout/auth is UI-only (Open Question 1). Wire this
    // to the real sign-out flow once auth is specified.
  }
```
with:
```dart
  Future<void> _onLogout(WidgetRef ref) {
    return ref.read(authControllerProvider.notifier).logout();
  }
```

Replace the call site:
```dart
                    onLogout: () => _onLogout(context),
```
with:
```dart
                    onLogout: () => _onLogout(ref),
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/akun/presentation/akun_screen_test.dart`
Expected: All 3 tests PASS.

- [ ] **Step 5: Run the full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: All PASS, no analyzer errors, no unused-import warnings (the
`BuildContext context` parameter is still used by `_onMenuTap`, only
`_onLogout`'s signature changes).

- [ ] **Step 6: Commit**

```bash
git add lib/features/akun/presentation/screens/akun_screen.dart test/features/akun/presentation/akun_screen_test.dart
git commit -m "feat(auth): wire Akun screen's Keluar action to real logout"
```

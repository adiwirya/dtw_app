# Tenant Order Board Real-Time Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the tenant "pesanan masuk" board's hard-coded mock with a real repository backed by the Downtown CMS API, delivering new orders live over Laravel Reverb instead of polling, and make a real login actually land a user in the tenant shell when appropriate.

**Architecture:** A shared `ApiException`/`mapDioError` helper (extracted from the existing auth feature) backs a new `TenantOrderRepository` (Dio) and a new `TenantRealtimeService` (a `laravel_reverb` client wrapped behind a small interface so it's fake-able in tests). `TenantOrderBoard` becomes an `AsyncNotifier` that fetches once, subscribes to the realtime service's `order.created` stream, and replays missed events on reconnect. `AuthController` is extended to derive the app flavor (busboy vs tenant) from the real login response's `scopes` instead of a hardcoded value, and to connect/disconnect the realtime service around login/logout.

**Tech Stack:** Flutter, Riverpod (`riverpod_generator`/`@riverpod`), Dio, `laravel_reverb` (new dependency), `flutter_test` with hand-rolled fakes (no mockito).

## Global Constraints

- No `freezed`/`json_serializable` — every model is a plain hand-written `@immutable` class with manual `fromJson`, matching every existing model in this codebase.
- No new abstract interface unless the codebase already has a precedent for one at that exact spot (`LocalStorage` is the only existing precedent) — `TenantRealtimeService` is the one new interface this plan introduces, justified because its concrete implementation wraps a third-party socket client that cannot be exercised in `flutter_test`.
- All repository methods map `DioException` → `ApiException` via the shared `mapDioError` helper — never a bespoke per-repository `_mapError`.
- Riverpod providers are `@riverpod`-generated (never a manually-written `Provider(...)`), matching every existing provider in this codebase.
- Every `Future`-returning Riverpod notifier method that can fail and is called from a screen must be awaited at the call site with a `try`/`catch` that shows a `SnackBar` on failure — no silently-swallowed mutation errors.
- Currency formatting always goes through the one shared `formatRupiah` function — never re-implemented.
- Run `dart run build_runner build --delete-conflicting-outputs` after adding/editing any `@riverpod` provider, before running its tests.
- Run `flutter analyze` with zero new warnings before each commit (this repo uses `very_good_analysis` + `riverpod_lint` + `custom_lint`).

---

## Task 1: Shared `ApiException` + `mapDioError` helper

**Files:**
- Modify: `lib/core/exceptions.dart`
- Modify: `lib/features/auth/data/repositories/auth_repository.dart:50-86` (replace `_mapError`)
- Test: `test/features/auth/data/repositories/auth_repository_test.dart` (no behavior change — used as the regression check)

**Interfaces:**
- Produces: `class ApiException implements Exception { ApiException({required String message, Map<String, List<String>>? fieldErrors}); String message; Map<String, List<String>>? fieldErrors; }`, `typedef AuthException = ApiException;`, `ApiException mapDioError(DioException error, {String Function(int?)? unauthorizedMessage})`.
- Consumes: nothing new (pure refactor of existing logic).

- [ ] **Step 1: Confirm the current auth tests pass before refactoring (baseline)**

Run: `flutter test test/features/auth/data/repositories/auth_repository_test.dart`
Expected: PASS (4 tests) — this is the regression baseline for this task.

- [ ] **Step 2: Rewrite `lib/core/exceptions.dart`**

```dart
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
```

- [ ] **Step 3: Update `AuthRepository` to use the shared helper**

In `lib/features/auth/data/repositories/auth_repository.dart`, delete the whole `AuthException _mapError(DioException error) { ... }` method (lines 50-86) and replace both call sites (`throw _mapError(error);`) with:

```dart
throw mapDioError(
  error,
  unauthorizedMessage: (_) => 'Username atau password salah.',
);
```

Remove the now-unused `import 'package:dtw_app/core/exceptions.dart';` duplicate if the analyzer flags it (it's still used for the `AuthException` alias in the file's public API, so keep the import — just remove the deleted method body).

- [ ] **Step 4: Run the auth repository tests again — confirm no regression**

Run: `flutter test test/features/auth/data/repositories/auth_repository_test.dart`
Expected: PASS (same 4 tests, unchanged assertions — `isA<AuthException>()` still matches since `AuthException` is now a `typedef` for `ApiException`).

- [ ] **Step 5: Run the full auth test suite + analyzer**

Run: `flutter test test/features/auth/` then `flutter analyze`
Expected: All PASS, zero new warnings.

- [ ] **Step 6: Commit**

```bash
git add lib/core/exceptions.dart lib/features/auth/data/repositories/auth_repository.dart
git commit -m "refactor(core): extract ApiException/mapDioError from AuthRepository for reuse"
```

---

## Task 2: Branch id resolution on login

**Files:**
- Modify: `lib/features/auth/data/models/login_response.dart`
- Modify: `lib/core/storage/secure_local_storage.dart` (add `tenantBranchIdStorageKey`)
- Modify: `lib/features/auth/data/repositories/auth_repository.dart` (`loginWithPassword` return type + persist branch id)
- Test: `test/features/auth/data/models/login_response_test.dart`
- Test: `test/features/auth/data/repositories/auth_repository_test.dart`

**Interfaces:**
- Consumes: `ApiException`/`mapDioError` from Task 1.
- Produces: `LoginResponse.branchId` (`String?`), `tenantBranchIdStorageKey` (`String` constant), `AuthRepository.loginWithPassword(...)` now returns `Future<LoginResponse>` (was `Future<void>`).

- [ ] **Step 1: Write the failing model test**

Add to `test/features/auth/data/models/login_response_test.dart`:

```dart
  test('LoginResponse.fromJson extracts branchId from a branch-typed scope',
      () {
    final json = {
      'meta': {
        'success': true,
        'message': 'Success',
        'code': 200,
        'trace_id': 'abc',
      },
      'data': {
        'access_token': 'tok_123',
        'user': {'id': 'u1', 'username': 'janji_jiwa_smlb'},
        'abilities': <dynamic>[],
        'scopes': [
          {'type': 'branch', 'tenant_branch_id': 'branch-1'},
        ],
      },
    };

    final result = LoginResponse.fromJson(json);

    expect(result.branchId, 'branch-1');
  });

  test('LoginResponse.fromJson leaves branchId null with no branch scope',
      () {
    final json = {
      'meta': {
        'success': true,
        'message': 'Success',
        'code': 200,
        'trace_id': 'abc',
      },
      'data': {
        'access_token': 'tok_123',
        'user': {'id': 'u1', 'username': 'budi'},
        'abilities': <dynamic>[],
        'scopes': <dynamic>[],
      },
    };

    final result = LoginResponse.fromJson(json);

    expect(result.branchId, isNull);
  });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/auth/data/models/login_response_test.dart`
Expected: FAIL — `LoginResponse` has no `branchId` getter (compile error).

- [ ] **Step 3: Add `branchId` parsing to `LoginResponse`**

Rewrite `lib/features/auth/data/models/login_response.dart`:

```dart
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
  const LoginResponse({
    required this.accessToken,
    required this.user,
    this.branchId,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return LoginResponse(
      accessToken: data['access_token'] as String,
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      branchId: _branchIdFromScopes(data['scopes']),
    );
  }

  final String accessToken;
  final AuthUser user;

  /// The tenant branch this session is scoped to, taken from the
  /// `scopes` entry whose `type` is `"branch"` — confirmed live against the
  /// Downtown CMS API: this value is **not** present on `data.user`.
  /// `null` for a session with no branch scope (a plain busboy/staff login).
  final String? branchId;

  static String? _branchIdFromScopes(Object? scopes) {
    if (scopes is! List) return null;
    for (final scope in scopes) {
      if (scope is Map && scope['type'] == 'branch') {
        return scope['tenant_branch_id'] as String?;
      }
    }
    return null;
  }
}
```

- [ ] **Step 4: Run the model test again — confirm it passes**

Run: `flutter test test/features/auth/data/models/login_response_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Add the storage key**

In `lib/core/storage/secure_local_storage.dart`, add alongside `authTokenStorageKey`:

```dart
/// Key the tenant branch id is stored under (only present for a
/// branch-scoped/tenant session) — read by [TenantOrderBoard] to know which
/// `branch_id` to fetch/subscribe with.
const tenantBranchIdStorageKey = 'tenant_branch_id';
```

- [ ] **Step 6: Change `AuthRepository.loginWithPassword` to return the response and persist the branch id**

In `lib/features/auth/data/repositories/auth_repository.dart`, replace the method:

```dart
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
      if (loginResponse.branchId != null) {
        await _localStorage.write(
          tenantBranchIdStorageKey,
          loginResponse.branchId!,
        );
      } else {
        await _localStorage.delete(tenantBranchIdStorageKey);
      }
      return loginResponse;
    } on DioException catch (error) {
      throw mapDioError(
        error,
        unauthorizedMessage: (_) => 'Username atau password salah.',
      );
    }
  }
```

Also clear it on logout — in the same file's `logout()`, change the `finally` block to:

```dart
    } finally {
      await _localStorage.delete(authTokenStorageKey);
      await _localStorage.delete(tenantBranchIdStorageKey);
    }
```

- [ ] **Step 7: Update the existing repository test's success assertion**

`test/features/auth/data/repositories/auth_repository_test.dart`'s first test currently only checks `storage.values[authTokenStorageKey]`. Extend its body (the JSON fixture already has no `scopes` key, which is fine — `_branchIdFromScopes` treats a missing key as `null`) by adding one more expectation right after the existing one:

```dart
    expect(storage.values[authTokenStorageKey], 'tok_123');
    expect(storage.values.containsKey(tenantBranchIdStorageKey), isFalse);
```

Add one new test in the same file (any position after the success test):

```dart
  test('loginWithPassword persists the branch id for a branch-scoped login',
      () async {
    final storage = FakeLocalStorage();
    final repository = AuthRepository(
      dio: cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Success',
          'code': 200,
          'trace_id': 'abc',
        },
        'data': {
          'access_token': 'tok_123',
          'user': {'id': 'u1', 'username': 'janji_jiwa_smlb'},
          'abilities': <dynamic>[],
          'scopes': [
            {'type': 'branch', 'tenant_branch_id': 'branch-1'},
          ],
        },
      }),
      localStorage: storage,
    );

    final response =
        await repository.loginWithPassword(username: 'janji_jiwa_smlb', password: 'secret');

    expect(response.branchId, 'branch-1');
    expect(storage.values[tenantBranchIdStorageKey], 'branch-1');
  });
```

Add the import at the top of the test file: `import 'package:dtw_app/core/storage/secure_local_storage.dart';` is already imported (it provides `authTokenStorageKey`) — `tenantBranchIdStorageKey` comes from the same import, no new import line needed.

- [ ] **Step 8: Run the full auth test suite**

Run: `flutter test test/features/auth/`
Expected: PASS, including the 2 new/modified assertions.

- [ ] **Step 9: Run analyzer**

Run: `flutter analyze`
Expected: zero new warnings.

- [ ] **Step 10: Commit**

```bash
git add lib/features/auth/data/models/login_response.dart lib/core/storage/secure_local_storage.dart lib/features/auth/data/repositories/auth_repository.dart test/features/auth/data/models/login_response_test.dart test/features/auth/data/repositories/auth_repository_test.dart
git commit -m "feat(auth): resolve and persist tenant branch id from login scopes"
```

---

## Task 3: Derive app flavor from login scopes, not a hardcoded value

**Files:**
- Modify: `lib/features/auth/presentation/providers/auth_controller.dart`
- Test: `test/features/auth/presentation/providers/auth_controller_test.dart`

**Interfaces:**
- Consumes: `AuthRepository.loginWithPassword` now returns `Future<LoginResponse>` (Task 2).
- Produces: `AuthController.login()` sets `appFlavorProvider` to `AppFlavor.tenant` when the response has a non-null `branchId`, else `AppFlavor.busboy`.

- [ ] **Step 1: Write the failing test — a branch-scoped login flips flavor to tenant**

Add to `test/features/auth/presentation/providers/auth_controller_test.dart`:

```dart
  test('login sets appFlavorProvider to tenant for a branch-scoped response',
      () async {
    final storage = FakeLocalStorage();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _repositoryReturning(200, {
            'meta': {
              'success': true,
              'message': 'Success',
              'code': 200,
              'trace_id': 'abc',
            },
            'data': {
              'access_token': 'tok_123',
              'user': {'id': 'u1', 'username': 'janji_jiwa_smlb'},
              'abilities': <dynamic>[],
              'scopes': [
                {'type': 'branch', 'tenant_branch_id': 'branch-1'},
              ],
            },
          }, storage),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .login(username: 'janji_jiwa_smlb', password: 'secret');

    expect(container.read(appFlavorProvider), AppFlavor.tenant);
  });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/auth/presentation/providers/auth_controller_test.dart`
Expected: FAIL — current code always sets `AppFlavor.busboy`.

- [ ] **Step 3: Update `AuthController.login()`**

In `lib/features/auth/presentation/providers/auth_controller.dart`, replace the `login` method body:

```dart
  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      final response = await ref.read(authRepositoryProvider).loginWithPassword(
            username: username,
            password: password,
          );
      ref.read(isLoggedInProvider.notifier).state = true;
      ref.read(appFlavorProvider.notifier).state =
          response.branchId != null ? AppFlavor.tenant : AppFlavor.busboy;
      state = const AuthState();
    } catch (error) {
      state = AuthState(error: error);
    }
  }
```

- [ ] **Step 4: Run the new test — confirm it passes**

Run: `flutter test test/features/auth/presentation/providers/auth_controller_test.dart`
Expected: PASS (4 tests total).

- [ ] **Step 5: Confirm the existing busboy-flavor test still passes unmodified**

The existing test `'login sets isLoggedInProvider and appFlavorProvider on success'` uses a fixture with no `scopes` key — `branchId` resolves to `null`, so flavor still resolves to `AppFlavor.busboy`. No changes needed to that test.

Run: `flutter test test/features/auth/`
Expected: PASS, all tests.

- [ ] **Step 6: Run analyzer, commit**

```bash
flutter analyze
git add lib/features/auth/presentation/providers/auth_controller.dart test/features/auth/presentation/providers/auth_controller_test.dart
git commit -m "feat(auth): derive app flavor from login scopes instead of hardcoding busboy"
```

---

## Task 4: Route both login-screen roles through real login

**Files:**
- Modify: `lib/features/auth/presentation/screens/login_screen.dart:68-90`
- Test: `test/features/auth/presentation/login_screen_test.dart`

**Interfaces:**
- Consumes: Task 3's flavor-from-scopes behavior.
- Produces: no new public interface — `_onMasuk()` no longer special-cases `LoginRole.tenan`.

- [ ] **Step 1: Write the failing test — a branch-scoped login lands on the tenant shell regardless of the tapped role card**

Replace the existing `'picking Tenan switches the whole app to the tenant shell'` test in `test/features/auth/presentation/login_screen_test.dart` with:

```dart
    testWidgets(
        'a branch-scoped login response lands on the tenant shell regardless of the tapped role card',
        (tester) async {
      await pumpApp(
        tester,
        statusCode: 200,
        body: {
          'meta': {
            'success': true,
            'message': 'Success',
            'code': 200,
            'trace_id': 'abc',
          },
          'data': {
            'access_token': 'tok_123',
            'user': {'id': 'u1', 'username': 'janji_jiwa_smlb'},
            'abilities': <dynamic>[],
            'scopes': [
              {'type': 'branch', 'tenant_branch_id': 'branch-1'},
            ],
          },
        },
      );

      // Tap Busboy (not Tenan) to prove the flavor comes from the response,
      // not from which role card was tapped.
      await tester.tap(find.text('Busboy'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(AppInput, 'Username'),
        'janji_jiwa_smlb',
      );
      await tester.enterText(find.widgetWithText(AppInput, 'Password'), 'secret');
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // The tenant Order home renders — no second login screen.
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('KFC\nFried Chicken'), findsOneWidget);
      // Tenant bottom nav labels confirm the flavor switch.
      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Laporan'), findsOneWidget);
    });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/auth/presentation/login_screen_test.dart`
Expected: FAIL — tapping Busboy + submitting currently calls the real API but the fixture's flavor never flips to tenant because `_onMasuk` doesn't even reach the API call path the way the test now drives it... actually re-check: this input already goes through the real (busboy) path today, so it will call the API today too — the failure mode is that **today** `AuthController` doesn't yet read `branchId` — wait, Task 3 already fixed that. So at this point in the plan, the actual expected failure is: none — if Tasks 1-3 are done, this specific new test might already pass since the busboy path already calls real login. Confirm by running it; if it unexpectedly passes already, proceed directly to Step 4 (no production code change needed for *this* test), but still do Step 3 for the Tenan-role stub removal since that's the behavior this task is actually meant to close out (a literal tap of "Tenan" must also call the real API, which today it does not).

Add a second test right after it to actually exercise the still-broken Tenan-role stub path:

```dart
    testWidgets('tapping Tenan and submitting also calls the real API',
        (tester) async {
      await pumpApp(
        tester,
        statusCode: 200,
        body: {
          'meta': {
            'success': true,
            'message': 'Success',
            'code': 200,
            'trace_id': 'abc',
          },
          'data': {
            'access_token': 'tok_123',
            'user': {'id': 'u1', 'username': 'janji_jiwa_smlb'},
            'abilities': <dynamic>[],
            'scopes': [
              {'type': 'branch', 'tenant_branch_id': 'branch-1'},
            ],
          },
        },
      );

      await tester.tap(find.text('Tenan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tenan'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(AppInput, 'Username'),
        'janji_jiwa_smlb',
      );
      await tester.enterText(find.widgetWithText(AppInput, 'Password'), 'secret');
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('KFC\nFried Chicken'), findsOneWidget);
    });
```

Run: `flutter test test/features/auth/presentation/login_screen_test.dart`
Expected: this second test FAILS — today, tapping "Tenan" and submitting with fields filled still hits the stub branch (`effectiveRole == LoginRole.tenan`), never calls the API, never fills validation, and just flips flavor immediately without checking the response at all (it would actually still land on the tenant shell today by coincidence of the stub, so re-check: the real distinguishing failure is that the stub **ignores the entered username/password and the fixture entirely** — to make the test meaningfully assert real-API usage, change the fixture's `statusCode` to `401` in this second test so the stub-vs-real distinction is unambiguous:

```dart
      await pumpApp(
        tester,
        statusCode: 401,
        body: {
          'meta': {
            'success': false,
            'message': 'Unauthorized',
            'code': 401,
            'trace_id': 'abc',
          },
          'errors': null,
        },
      );

      await tester.tap(find.text('Tenan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tenan'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(AppInput, 'Username'),
        'janji_jiwa_smlb',
      );
      await tester.enterText(find.widgetWithText(AppInput, 'Password'), 'wrong');
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // A real API call was made and its 401 error surfaced — today's stub
      // would have flipped straight to the tenant shell instead.
      expect(find.text('Username atau password salah.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
```

Run: `flutter test test/features/auth/presentation/login_screen_test.dart`
Expected: this version FAILS today (stub ignores the 401 fixture and flips to tenant shell regardless).

- [ ] **Step 3: Remove the Tenan-role stub branch in `_onMasuk`**

In `lib/features/auth/presentation/screens/login_screen.dart`, replace `_onMasuk`:

```dart
  Future<void> _onMasuk() async {
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

Remove the now-unused `AppFlavor`/`isLoggedInProvider` direct references if the analyzer flags the `flavor.dart` import as unused (check: `appFlavorProvider`/`isLoggedInProvider` are no longer referenced directly in this file at all after this change — they're only touched via `AuthController` now). If the import becomes unused, delete `import 'package:dtw_app/core/flavor.dart';` from this file.

- [ ] **Step 4: Run the login screen tests — confirm they pass**

Run: `flutter test test/features/auth/presentation/login_screen_test.dart`
Expected: PASS, all tests including the two new/replaced ones.

- [ ] **Step 5: Run the full test suite for regressions in dependent screens**

Run: `flutter test test/features/auth/ test/features/tenant/tenant_shell_test.dart`
Expected: PASS. (`tenant_shell_test.dart` is the one flagged in memory as covering the flavor-switch shell boot — confirm it doesn't assume the old stub path.)

- [ ] **Step 6: Run analyzer, commit**

```bash
flutter analyze
git add lib/features/auth/presentation/screens/login_screen.dart test/features/auth/presentation/login_screen_test.dart
git commit -m "feat(auth): route both login role cards through real authentication"
```

---

## Task 5: Add the `laravel_reverb` dependency and Reverb connection config

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/realtime/reverb_config.dart`

**Interfaces:**
- Produces: `ReverbConfig` class with `host`, `appKey`, `useTls`, `port` static constants.

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, under `dependencies:` (alphabetically, after `go_router`):

```yaml
  go_router: ^17.3.0
  laravel_reverb: ^0.6.0
  obra_icons: ^1.0.0
```

- [ ] **Step 2: Fetch it**

Run: `flutter pub get`
Expected: resolves successfully. **Before writing Task 6**, open
`.pub-cache`'s downloaded `laravel_reverb` package source (or its
pub.dev-listed example) and confirm the exact constructor/method names
used below (`Reverb(...)`, `.private(...)`, `.listen(...)`, `.states`,
`.onReconnected(...)`) match the installed version — this plan's Task 6
code was written from the package's published docs/README, not from
reading its source directly, so a naming mismatch is the single most
likely snag in this whole plan. If a name differs, adjust Task 6's
`ReverbTenantRealtimeService` internals only — the `TenantRealtimeService`
interface and every other file that depends on it stay unchanged.

- [ ] **Step 3: Create `lib/core/realtime/reverb_config.dart`**

```dart
/// Connection constants for the Downtown CMS Laravel Reverb server.
///
/// [appKey] is a Pusher/Reverb *app key* — a public client-side identifier
/// (not a secret), the same trust level as [host] itself.
class ReverbConfig {
  const ReverbConfig._();

  static const host = 'dtw-cms.gadingemerald.com';
  static const appKey = 'qvata3lm1xtqpocb9g2i';
  static const useTls = true;

  /// Assumed to be reverse-proxied on the same port as the REST API (443)
  /// since Reverb runs on "the same domain" per the backend team — verify on
  /// the first real connection attempt; if it fails to connect, the actual
  /// Reverb port needs to be obtained separately.
  static const port = 443;

  static String get authEndpoint => 'https://$host/broadcasting/auth';
}
```

- [ ] **Step 4: Run analyzer, commit**

```bash
flutter analyze
git add pubspec.yaml pubspec.lock lib/core/realtime/reverb_config.dart
git commit -m "feat(realtime): add laravel_reverb dependency and connection config"
```

---

## Task 6: `TenantRealtimeService` interface + Reverb-backed implementation + test fake

**Files:**
- Create: `lib/core/realtime/tenant_realtime_service.dart`
- Create: `test/support/fake_tenant_realtime_service.dart`

**Interfaces:**
- Consumes: `ReverbConfig` (Task 5).
- Produces:
  ```dart
  abstract class TenantRealtimeService {
    Future<void> connect({required String token, required String branchId});
    Future<void> disconnect();
    Stream<Map<String, dynamic>> get orderCreated;
    Stream<void> get reconnected;
  }
  ```
  plus `@riverpod TenantRealtimeService tenantRealtimeService(Ref ref)` and, in the test support file, `class FakeTenantRealtimeService implements TenantRealtimeService` with public `StreamController`s the test can push into (`emitOrderCreated(Map)`, `emitReconnected()`) and `connectCalls`/`disconnectCallCount` for assertions.

- [ ] **Step 1: Write `lib/core/realtime/tenant_realtime_service.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_reverb/laravel_reverb.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'reverb_config.dart';

part 'tenant_realtime_service.g.dart';

/// Delivers real-time order events for the currently-connected tenant
/// branch. Abstracted behind an interface so tests can substitute a fake
/// instead of opening a real socket — see
/// `test/support/fake_tenant_realtime_service.dart`.
abstract class TenantRealtimeService {
  /// Connects and subscribes to `private-branch.<branchId>`, authenticating
  /// with [token] against `POST /broadcasting/auth`. Safe to call again
  /// with a new token/branchId (e.g. after a fresh login) — implementations
  /// disconnect any existing session first.
  Future<void> connect({required String token, required String branchId});

  /// Unsubscribes and disconnects. Safe to call when not connected.
  Future<void> disconnect();

  /// Emits the decoded payload of every `order.created` event received on
  /// the subscribed channel.
  Stream<Map<String, dynamic>> get orderCreated;

  /// Emits once each time the underlying connection re-establishes after a
  /// drop (not on the very first connect) — the signal to run the
  /// broadcast-replay gap-fill.
  Stream<void> get reconnected;
}

class ReverbTenantRealtimeService implements TenantRealtimeService {
  Reverb? _reverb;
  final _orderCreatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _reconnectedController = StreamController<void>.broadcast();
  bool _hasConnectedBefore = false;

  @override
  Stream<Map<String, dynamic>> get orderCreated =>
      _orderCreatedController.stream;

  @override
  Stream<void> get reconnected => _reconnectedController.stream;

  @override
  Future<void> connect({required String token, required String branchId}) async {
    await disconnect();

    final reverb = Reverb(
      host: ReverbConfig.host,
      port: ReverbConfig.port,
      appKey: ReverbConfig.appKey,
      useTls: ReverbConfig.useTls,
      authEndpoint: ReverbConfig.authEndpoint,
      authHeaders: () async => {'Authorization': 'Bearer $token'},
    );
    _reverb = reverb;

    reverb.states.listen((_) {
      if (_hasConnectedBefore) {
        _reconnectedController.add(null);
      }
      _hasConnectedBefore = true;
    });

    await reverb.connect();
    reverb.private('branch.$branchId').listen('order.created', (data) {
      if (data is Map<String, dynamic>) {
        _orderCreatedController.add(data);
      }
    });
  }

  @override
  Future<void> disconnect() async {
    final reverb = _reverb;
    _reverb = null;
    _hasConnectedBefore = false;
    if (reverb != null) {
      await reverb.disconnect();
    }
  }
}

@Riverpod(keepAlive: true)
TenantRealtimeService tenantRealtimeService(Ref ref) =>
    ReverbTenantRealtimeService();
```

Add `import 'dart:async';` at the top for `StreamController`.

**Note:** the exact `Reverb` constructor/method names above (`states`,
`.private(...).listen(...)`, `.connect()`, `.disconnect()`) must be
confirmed against the actually-installed package per Task 5 Step 2 before
this compiles — adjust only inside `ReverbTenantRealtimeService` if they
differ; `TenantRealtimeService`, `FakeTenantRealtimeService`, and every
downstream consumer stay unchanged either way.

- [ ] **Step 2: Generate the Riverpod code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/core/realtime/tenant_realtime_service.g.dart` is generated with no errors.

- [ ] **Step 3: Write the test fake**

Create `test/support/fake_tenant_realtime_service.dart`:

```dart
import 'dart:async';

import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';

/// In-memory [TenantRealtimeService] test double. Tests push events with
/// [emitOrderCreated]/[emitReconnected]; [connectCalls] and
/// [disconnectCallCount] let tests assert connect/disconnect lifecycle
/// wiring without a real socket.
class FakeTenantRealtimeService implements TenantRealtimeService {
  final List<({String token, String branchId})> connectCalls = [];
  int disconnectCallCount = 0;

  final _orderCreatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _reconnectedController = StreamController<void>.broadcast();

  @override
  Stream<Map<String, dynamic>> get orderCreated =>
      _orderCreatedController.stream;

  @override
  Stream<void> get reconnected => _reconnectedController.stream;

  @override
  Future<void> connect({required String token, required String branchId}) async {
    connectCalls.add((token: token, branchId: branchId));
  }

  @override
  Future<void> disconnect() async {
    disconnectCallCount++;
  }

  void emitOrderCreated(Map<String, dynamic> payload) {
    _orderCreatedController.add(payload);
  }

  void emitReconnected() {
    _reconnectedController.add(null);
  }

  Future<void> close() async {
    await _orderCreatedController.close();
    await _reconnectedController.close();
  }
}
```

- [ ] **Step 4: Run analyzer (no behavioral test yet — this is scaffolding consumed by later tasks)**

Run: `flutter analyze`
Expected: zero new warnings. (The fake gets its first real exercise in Task 7 and Task 10's tests.)

- [ ] **Step 5: Commit**

```bash
git add lib/core/realtime/tenant_realtime_service.dart lib/core/realtime/tenant_realtime_service.g.dart test/support/fake_tenant_realtime_service.dart
git commit -m "feat(realtime): add TenantRealtimeService with Reverb-backed impl and fake"
```

---

## Task 7: Wire realtime connect/disconnect into the auth lifecycle

**Files:**
- Modify: `lib/features/auth/presentation/providers/auth_controller.dart`
- Modify: `lib/core/network/dio_provider.dart` (401 interceptor also disconnects)
- Test: `test/features/auth/presentation/providers/auth_controller_test.dart`

**Interfaces:**
- Consumes: `TenantRealtimeService`/`tenantRealtimeServiceProvider` (Task 6), `FakeTenantRealtimeService` (Task 6).
- Produces: no new public interface — behavioral wiring only.

- [ ] **Step 1: Write the failing test — login connects, logout disconnects**

Add to `test/features/auth/presentation/providers/auth_controller_test.dart`:

```dart
  test('login connects the realtime service for a branch-scoped response',
      () async {
    final storage = FakeLocalStorage();
    final realtime = FakeTenantRealtimeService();
    addTearDown(realtime.close);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _repositoryReturning(200, {
            'meta': {
              'success': true,
              'message': 'Success',
              'code': 200,
              'trace_id': 'abc',
            },
            'data': {
              'access_token': 'tok_123',
              'user': {'id': 'u1', 'username': 'janji_jiwa_smlb'},
              'abilities': <dynamic>[],
              'scopes': [
                {'type': 'branch', 'tenant_branch_id': 'branch-1'},
              ],
            },
          }, storage),
        ),
        tenantRealtimeServiceProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .login(username: 'janji_jiwa_smlb', password: 'secret');

    expect(realtime.connectCalls, [(token: 'tok_123', branchId: 'branch-1')]);
  });

  test('login does not connect the realtime service for a busboy response',
      () async {
    final storage = FakeLocalStorage();
    final realtime = FakeTenantRealtimeService();
    addTearDown(realtime.close);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _repositoryReturning(200, {
            'meta': {
              'success': true,
              'message': 'Success',
              'code': 200,
              'trace_id': 'abc',
            },
            'data': {
              'access_token': 'tok_123',
              'user': {'id': 'u1', 'username': 'budi'},
            },
          }, storage),
        ),
        tenantRealtimeServiceProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .login(username: 'budi', password: 'secret');

    expect(realtime.connectCalls, isEmpty);
  });

  test('logout disconnects the realtime service', () async {
    final storage = FakeLocalStorage()..values[authTokenStorageKey] = 'tok_123';
    final realtime = FakeTenantRealtimeService();
    addTearDown(realtime.close);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _repositoryReturning(200, {
            'meta': {
              'success': true,
              'message': 'Success',
              'code': 200,
              'trace_id': 'abc',
            },
          }, storage),
        ),
        tenantRealtimeServiceProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).logout();

    expect(realtime.disconnectCallCount, 1);
  });
```

Add the import at the top of the test file:
```dart
import '../../../../support/fake_tenant_realtime_service.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/auth/presentation/providers/auth_controller_test.dart`
Expected: FAIL — `AuthController` doesn't reference `tenantRealtimeServiceProvider` yet.

- [ ] **Step 3: Wire `AuthController`**

In `lib/features/auth/presentation/providers/auth_controller.dart`, add the import:

```dart
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
```

Update `login`:

```dart
  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      final response = await ref.read(authRepositoryProvider).loginWithPassword(
            username: username,
            password: password,
          );
      ref.read(isLoggedInProvider.notifier).state = true;
      final branchId = response.branchId;
      ref.read(appFlavorProvider.notifier).state =
          branchId != null ? AppFlavor.tenant : AppFlavor.busboy;
      if (branchId != null) {
        await ref.read(tenantRealtimeServiceProvider).connect(
              token: response.accessToken,
              branchId: branchId,
            );
      }
      state = const AuthState();
    } catch (error) {
      state = AuthState(error: error);
    }
  }
```

Update `logout`:

```dart
  Future<void> logout() async {
    await ref.read(tenantRealtimeServiceProvider).disconnect();
    await ref.read(authRepositoryProvider).logout();
    ref.read(isLoggedInProvider.notifier).state = false;
  }
```

- [ ] **Step 4: Run the tests again — confirm they pass**

Run: `flutter test test/features/auth/presentation/providers/auth_controller_test.dart`
Expected: PASS (7 tests total).

- [ ] **Step 5: Also disconnect on a 401 session drop**

In `lib/core/network/dio_provider.dart`, update the `onError` handler:

```dart
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await ref.read(localStorageProvider).delete(authTokenStorageKey);
          await ref.read(tenantRealtimeServiceProvider).disconnect();
          ref.read(isLoggedInProvider.notifier).state = false;
        }
        handler.next(error);
      },
```

Add the import: `import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';`

There is no existing test file for `dio_provider.dart`'s interceptor — do not add one now (no established pattern for testing an `InterceptorsWrapper` in isolation in this codebase, and it is exercised indirectly by every repository test that hits a 401 fixture through `cannedDio`, which bypasses `dioProvider` entirely and so does not need updating).

- [ ] **Step 6: Run the full test suite + analyzer**

Run: `flutter test` then `flutter analyze`
Expected: PASS, zero new warnings.

- [ ] **Step 7: Commit**

```bash
git add lib/features/auth/presentation/providers/auth_controller.dart lib/core/network/dio_provider.dart test/features/auth/presentation/providers/auth_controller_test.dart
git commit -m "feat(auth): connect/disconnect the tenant realtime service around the session lifecycle"
```

---

## Task 8: `TenantOrder` model, status mapping, and the shared currency formatter

**Files:**
- Create: `lib/core/utils/currency.dart`
- Modify: `lib/features/tenant/presentation/screens/tenant_reject_order_screen.dart` (remove local `formatRupiah`, import + re-export the shared one)
- Create: `lib/features/tenant/data/models/tenant_order.dart`
- Test: `test/features/tenant/data/models/tenant_order_test.dart`

**Interfaces:**
- Consumes: `IncomingOrderData`/`IncomingOrderStatus` (existing, `lib/features/tenant/presentation/widgets/incoming_order_card.dart`).
- Produces: `String formatRupiah(int value)` (moved), `enum TenantOrderStatus`, `TenantOrderStatus tenantOrderStatusFromWire(String value)`, `String tenantOrderStatusToWire(TenantOrderStatus status)`, `IncomingOrderStatus incomingOrderStatusFromBackend(TenantOrderStatus status)`, `class TenantOrder` with `TenantOrder.fromJson(Map<String, dynamic>)`, `.toIncomingOrderData()`, `.copyWith({TenantOrderStatus? status})`.

- [ ] **Step 1: Extract the currency formatter**

Create `lib/core/utils/currency.dart`:

```dart
/// Formats an integer rupiah amount as `Rp35.000` (thousands separated by
/// `.`). Shared by every feature that renders a rupiah amount — do not
/// re-implement this per feature.
String formatRupiah(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return 'Rp$buffer';
}
```

In `lib/features/tenant/presentation/screens/tenant_reject_order_screen.dart`, delete the local `formatRupiah` function (lines 12-21) and add near the top of the import block:

```dart
export 'package:dtw_app/core/utils/currency.dart' show formatRupiah;
import 'package:dtw_app/core/utils/currency.dart';
```

(The `export` keeps `test/features/tenant/presentation/tenant_reject_order_screen_test.dart`'s existing unqualified `formatRupiah(...)` calls working with zero test changes, since that test imports this screen file directly.)

- [ ] **Step 2: Confirm the untouched reject-screen currency test still passes**

Run: `flutter test test/features/tenant/presentation/tenant_reject_order_screen_test.dart -n "formatRupiah"`
Expected: PASS (1 test) — proves the `export` re-exposes the function correctly.

- [ ] **Step 3: Write the failing model test**

Create `test/features/tenant/data/models/tenant_order_test.dart`:

```dart
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TenantOrder.fromJson', () {
    test('parses the live GET /v1/orders item shape', () {
      final order = TenantOrder.fromJson({
        'id': '76257d18-9f17-41dd-81a3-98404a81eddc',
        'order_group_id': 'ae6322b3-e165-49ca-a6ba-7baf30377cad',
        'branch_id': '0bac8a76-dd70-4345-9d16-742c585e676a',
        'receipt_number': 'RCP-20260807-IOOXVF',
        'grand_total': 21000,
        'order_status': 'PENDING',
        'created_at': '2026-08-07 09:24:08',
        'updated_at': '2026-08-07 09:24:08',
        'items': <dynamic>[],
      });

      expect(order.id, '76257d18-9f17-41dd-81a3-98404a81eddc');
      expect(order.branchId, '0bac8a76-dd70-4345-9d16-742c585e676a');
      expect(order.receiptNumber, 'RCP-20260807-IOOXVF');
      expect(order.grandTotal, 21000);
      expect(order.status, TenantOrderStatus.pending);
      expect(order.createdAt, DateTime(2026, 8, 7, 9, 24, 8));
      expect(order.broadcastEventId, isNull);
    });

    test('parses a socket payload carrying broadcast_event_id', () {
      final order = TenantOrder.fromJson({
        'id': 'order-1',
        'order_group_id': 'group-1',
        'branch_id': 'branch-1',
        'receipt_number': 'RCP-1',
        'grand_total': 40000,
        'order_status': 'PENDING',
        'created_at': '2026-08-11 10:36:00',
        'updated_at': '2026-08-11 10:36:00',
        'items': <dynamic>[],
        'broadcast_event_id': 123,
      });

      expect(order.broadcastEventId, 123);
    });
  });

  group('tenantOrderStatusFromWire / tenantOrderStatusToWire', () {
    test('round-trips every enum value', () {
      for (final status in TenantOrderStatus.values) {
        final wire = tenantOrderStatusToWire(status);
        expect(tenantOrderStatusFromWire(wire), status);
      }
    });

    test('throws on an unknown wire value', () {
      expect(() => tenantOrderStatusFromWire('WAT'), throwsFormatException);
    });
  });

  group('incomingOrderStatusFromBackend', () {
    test('maps pending to baru', () {
      expect(
        incomingOrderStatusFromBackend(TenantOrderStatus.pending),
        IncomingOrderStatus.baru,
      );
    });

    test('maps preparing to diproses', () {
      expect(
        incomingOrderStatusFromBackend(TenantOrderStatus.preparing),
        IncomingOrderStatus.diproses,
      );
    });

    test('maps ready, completed and partialCompleted to selesai', () {
      expect(
        incomingOrderStatusFromBackend(TenantOrderStatus.ready),
        IncomingOrderStatus.selesai,
      );
      expect(
        incomingOrderStatusFromBackend(TenantOrderStatus.completed),
        IncomingOrderStatus.selesai,
      );
      expect(
        incomingOrderStatusFromBackend(TenantOrderStatus.partialCompleted),
        IncomingOrderStatus.selesai,
      );
    });

    test('throws for cancelled (callers must filter cancelled out first)',
        () {
      expect(
        () => incomingOrderStatusFromBackend(TenantOrderStatus.cancelled),
        throwsStateError,
      );
    });
  });

  group('TenantOrder.toIncomingOrderData', () {
    test(
        'maps receiptNumber to tableName, formats time, leaves items empty',
        () {
      final order = TenantOrder.fromJson({
        'id': 'order-1',
        'order_group_id': 'group-1',
        'branch_id': 'branch-1',
        'receipt_number': 'RCP-20260807-IOOXVF',
        'grand_total': 21000,
        'order_status': 'PENDING',
        'created_at': '2026-08-07 09:24:08',
        'updated_at': '2026-08-07 09:24:08',
        'items': <dynamic>[],
      });

      final data = order.toIncomingOrderData();

      expect(data.orderId, 'order-1');
      expect(data.tableName, 'RCP-20260807-IOOXVF');
      expect(data.time, '09:24');
      expect(data.status, IncomingOrderStatus.baru);
      expect(data.items, isEmpty);
      expect(data.total, 'Rp21.000');
      expect(data.note, isNull);
    });
  });

  group('TenantOrder.copyWith', () {
    test('overrides only status, keeps every other field', () {
      final order = TenantOrder.fromJson({
        'id': 'order-1',
        'order_group_id': 'group-1',
        'branch_id': 'branch-1',
        'receipt_number': 'RCP-1',
        'grand_total': 21000,
        'order_status': 'PENDING',
        'created_at': '2026-08-07 09:24:08',
        'updated_at': '2026-08-07 09:24:08',
        'items': <dynamic>[],
      });

      final updated = order.copyWith(status: TenantOrderStatus.preparing);

      expect(updated.status, TenantOrderStatus.preparing);
      expect(updated.id, order.id);
      expect(updated.receiptNumber, order.receiptNumber);
    });
  });
}
```

- [ ] **Step 4: Run the test to verify it fails**

Run: `flutter test test/features/tenant/data/models/tenant_order_test.dart`
Expected: FAIL — `lib/features/tenant/data/models/tenant_order.dart` doesn't exist yet.

- [ ] **Step 5: Write `lib/features/tenant/data/models/tenant_order.dart`**

```dart
import 'package:dtw_app/core/utils/currency.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter/foundation.dart';

/// Mirrors the backend's `order_status` enum (confirmed live: values are
/// UPPER_SNAKE_CASE strings). Distinct from the UI-only [IncomingOrderStatus]
/// — see [incomingOrderStatusFromBackend] for the translation.
enum TenantOrderStatus {
  pending,
  preparing,
  ready,
  completed,
  partialCompleted,
  cancelled,
}

TenantOrderStatus tenantOrderStatusFromWire(String value) => switch (value) {
      'PENDING' => TenantOrderStatus.pending,
      'PREPARING' => TenantOrderStatus.preparing,
      'READY' => TenantOrderStatus.ready,
      'COMPLETED' => TenantOrderStatus.completed,
      'PARTIAL_COMPLETED' => TenantOrderStatus.partialCompleted,
      'CANCELLED' => TenantOrderStatus.cancelled,
      _ => throw FormatException('Unknown order_status: $value'),
    };

String tenantOrderStatusToWire(TenantOrderStatus status) => switch (status) {
      TenantOrderStatus.pending => 'PENDING',
      TenantOrderStatus.preparing => 'PREPARING',
      TenantOrderStatus.ready => 'READY',
      TenantOrderStatus.completed => 'COMPLETED',
      TenantOrderStatus.partialCompleted => 'PARTIAL_COMPLETED',
      TenantOrderStatus.cancelled => 'CANCELLED',
    };

/// Translates a backend status into the three UI sub-tabs. [TenantOrder]
/// lists are filtered to exclude [TenantOrderStatus.cancelled] before this
/// is ever called (see `TenantOrderRepository`/`TenantOrderBoard`) — calling
/// it with `cancelled` is a programming error, not a case to render.
IncomingOrderStatus incomingOrderStatusFromBackend(TenantOrderStatus status) {
  switch (status) {
    case TenantOrderStatus.pending:
      return IncomingOrderStatus.baru;
    case TenantOrderStatus.preparing:
      return IncomingOrderStatus.diproses;
    case TenantOrderStatus.ready:
    case TenantOrderStatus.completed:
    case TenantOrderStatus.partialCompleted:
      return IncomingOrderStatus.selesai;
    case TenantOrderStatus.cancelled:
      throw StateError(
        'cancelled orders must be filtered out before status mapping',
      );
  }
}

/// A tenant-branch order, as returned by `GET /v1/orders` or delivered live
/// via the `order.created` Reverb event.
///
/// **Known gap (see the 2026-08-11 design doc):** the live API's order
/// shape has no table name and an always-empty `items` array — there is no
/// confirmed source for either yet. [toIncomingOrderData] fills the UI's
/// `tableName` slot with [receiptNumber] (real data, repurposed) and always
/// renders an empty item list until the real shape is found.
@immutable
class TenantOrder {
  const TenantOrder({
    required this.id,
    required this.orderGroupId,
    required this.branchId,
    required this.receiptNumber,
    required this.grandTotal,
    required this.status,
    required this.createdAt,
    this.broadcastEventId,
  });

  factory TenantOrder.fromJson(Map<String, dynamic> json) {
    return TenantOrder(
      id: json['id'] as String,
      orderGroupId: json['order_group_id'] as String,
      branchId: json['branch_id'] as String,
      receiptNumber: json['receipt_number'] as String,
      grandTotal: (json['grand_total'] as num).toInt(),
      status: tenantOrderStatusFromWire(json['order_status'] as String),
      createdAt:
          DateTime.parse((json['created_at'] as String).replaceFirst(' ', 'T')),
      broadcastEventId: json['broadcast_event_id'] as int?,
    );
  }

  final String id;
  final String orderGroupId;
  final String branchId;
  final String receiptNumber;
  final int grandTotal;
  final TenantOrderStatus status;
  final DateTime createdAt;
  final int? broadcastEventId;

  TenantOrder copyWith({TenantOrderStatus? status}) => TenantOrder(
        id: id,
        orderGroupId: orderGroupId,
        branchId: branchId,
        receiptNumber: receiptNumber,
        grandTotal: grandTotal,
        status: status ?? this.status,
        createdAt: createdAt,
        broadcastEventId: broadcastEventId,
      );

  IncomingOrderData toIncomingOrderData() {
    final hh = createdAt.hour.toString().padLeft(2, '0');
    final mm = createdAt.minute.toString().padLeft(2, '0');
    return IncomingOrderData(
      orderId: id,
      tableName: receiptNumber,
      time: '$hh:$mm',
      status: incomingOrderStatusFromBackend(status),
      items: const [],
      total: formatRupiah(grandTotal),
    );
  }
}
```

- [ ] **Step 6: Run the test again — confirm it passes**

Run: `flutter test test/features/tenant/data/models/tenant_order_test.dart`
Expected: PASS (12 tests).

- [ ] **Step 7: Run analyzer, commit**

```bash
flutter analyze
git add lib/core/utils/currency.dart lib/features/tenant/presentation/screens/tenant_reject_order_screen.dart lib/features/tenant/data/models/tenant_order.dart test/features/tenant/data/models/tenant_order_test.dart
git commit -m "feat(tenant): add TenantOrder model with confirmed live API field mapping"
```

---

## Task 9: `TenantOrderRepository`

**Files:**
- Create: `lib/features/tenant/data/repositories/tenant_order_repository.dart`
- Test: `test/features/tenant/data/repositories/tenant_order_repository_test.dart`

**Interfaces:**
- Consumes: `TenantOrder`/`TenantOrderStatus`/`tenantOrderStatusToWire` (Task 8), `ApiException`/`mapDioError` (Task 1), `dioProvider` (existing).
- Produces:
  ```dart
  class TenantOrderRepository {
    TenantOrderRepository({required Dio dio});
    Future<List<TenantOrder>> fetchOrders({required String branchId});
    Future<void> updateStatus(String orderId, {required TenantOrderStatus status, String? reason});
    Future<List<TenantOrder>> fetchMissedEvents({required String branchId, required int afterId});
  }
  @riverpod TenantOrderRepository tenantOrderRepository(Ref ref)
  ```

- [ ] **Step 1: Write the failing tests**

Create `test/features/tenant/data/repositories/tenant_order_repository_test.dart`:

```dart
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_order_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/canned_dio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('fetchOrders', () {
    test('parses the live response shape and passes branch_id as a query param', () async {
      final dio = cannedDio(200, {
        'meta': {'success': true, 'message': 'Success', 'code': 200, 'trace_id': 'abc'},
        'data': [
          {
            'id': 'order-1',
            'order_group_id': 'group-1',
            'branch_id': 'branch-1',
            'receipt_number': 'RCP-1',
            'grand_total': 21000,
            'order_status': 'PENDING',
            'created_at': '2026-08-07 09:24:08',
            'updated_at': '2026-08-07 09:24:08',
            'items': <dynamic>[],
          },
        ],
      });
      final repository = TenantOrderRepository(dio: dio);

      final orders = await repository.fetchOrders(branchId: 'branch-1');

      expect(orders, hasLength(1));
      expect(orders.single.id, 'order-1');
      expect(
        (dio.httpClientAdapter as CannedAdapter).lastRequest!.queryParameters,
        {'branch_id': 'branch-1'},
      );
    });

    test('throws ApiException with the required-field message on 422', () async {
      final dio = cannedDio(422, {
        'meta': {'success': false, 'message': 'Validation failed.', 'code': 422, 'trace_id': 'abc'},
        'errors': {
          'branch_id': ['The branch id field is required.'],
        },
      });
      final repository = TenantOrderRepository(dio: dio);

      await expectLater(
        repository.fetchOrders(branchId: 'branch-1'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'The branch id field is required.',
          ),
        ),
      );
    });
  });

  group('updateStatus', () {
    test('PATCHes order_status with the wire enum value', () async {
      final dio = cannedDio(200, {
        'meta': {'success': true, 'message': 'Success', 'code': 200, 'trace_id': 'abc'},
      });
      final repository = TenantOrderRepository(dio: dio);

      await repository.updateStatus('order-1', status: TenantOrderStatus.preparing);

      final adapter = dio.httpClientAdapter as CannedAdapter;
      expect(adapter.lastRequest!.path, '/v1/orders/order-1/status');
      expect(adapter.lastRequest!.method, 'PATCH');
      expect(adapter.lastRequest!.data, {'order_status': 'PREPARING'});
    });

    test('includes reason when provided', () async {
      final dio = cannedDio(200, {
        'meta': {'success': true, 'message': 'Success', 'code': 200, 'trace_id': 'abc'},
      });
      final repository = TenantOrderRepository(dio: dio);

      await repository.updateStatus(
        'order-1',
        status: TenantOrderStatus.cancelled,
        reason: 'Stok Habis',
      );

      final adapter = dio.httpClientAdapter as CannedAdapter;
      expect(adapter.lastRequest!.data, {
        'order_status': 'CANCELLED',
        'reason': 'Stok Habis',
      });
    });

    test('throws a mapped ApiException on failure', () async {
      final dio = cannedDio(500, {
        'meta': {'success': false, 'message': 'Error', 'code': 500, 'trace_id': 'abc'},
      });
      final repository = TenantOrderRepository(dio: dio);

      await expectLater(
        repository.updateStatus('order-1', status: TenantOrderStatus.preparing),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Terjadi kesalahan. Coba lagi.',
          ),
        ),
      );
    });
  });

  group('fetchMissedEvents', () {
    test('passes branch_id and after_id as query params', () async {
      final dio = cannedDio(200, {
        'meta': {'success': true, 'message': 'Success', 'code': 200, 'trace_id': 'abc'},
        'data': <dynamic>[],
      });
      final repository = TenantOrderRepository(dio: dio);

      final orders =
          await repository.fetchMissedEvents(branchId: 'branch-1', afterId: 42);

      expect(orders, isEmpty);
      expect(
        (dio.httpClientAdapter as CannedAdapter).lastRequest!.queryParameters,
        {'branch_id': 'branch-1', 'after_id': 42},
      );
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/tenant/data/repositories/tenant_order_repository_test.dart`
Expected: FAIL — the repository file doesn't exist yet.

- [ ] **Step 3: Write `lib/features/tenant/data/repositories/tenant_order_repository.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/network/dio_provider.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tenant_order_repository.g.dart';

class TenantOrderRepository {
  TenantOrderRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<TenantOrder>> fetchOrders({required String branchId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/orders',
        queryParameters: {'branch_id': branchId},
      );
      final data = response.data!['data'] as List;
      return data
          .map((json) => TenantOrder.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> updateStatus(
    String orderId, {
    required TenantOrderStatus status,
    String? reason,
  }) async {
    try {
      await _dio.patch<void>(
        '/v1/orders/$orderId/status',
        data: {
          'order_status': tenantOrderStatusToWire(status),
          if (reason != null) 'reason': reason,
        },
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<List<TenantOrder>> fetchMissedEvents({
    required String branchId,
    required int afterId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/broadcast/replay',
        queryParameters: {'branch_id': branchId, 'after_id': afterId},
      );
      final data = response.data!['data'] as List;
      return data
          .map((json) => TenantOrder.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}

@riverpod
TenantOrderRepository tenantOrderRepository(Ref ref) =>
    TenantOrderRepository(dio: ref.watch(dioProvider));
```

**Open item carried from the spec, not resolved here:** the `PATCH`
body's `order_status` key name and whether `reason` is accepted by the
real API are best-guess (matched to the list response's field naming) and
were deliberately not verified against the live test order to avoid
mutating real data without sign-off. If manual QA (Task 11) shows the
real API rejects this shape, adjust `updateStatus` only — nothing else in
this file depends on the exact body shape.

- [ ] **Step 4: Run the tests again — confirm they pass**

Run: `flutter test test/features/tenant/data/repositories/tenant_order_repository_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Run analyzer, commit**

```bash
flutter analyze
git add lib/features/tenant/data/repositories/tenant_order_repository.dart lib/features/tenant/data/repositories/tenant_order_repository.g.dart test/features/tenant/data/repositories/tenant_order_repository_test.dart
git commit -m "feat(tenant): add TenantOrderRepository backed by the real Downtown CMS API"
```

---

## Task 10: Rewrite `TenantOrderBoard` as a real, realtime-fed `AsyncNotifier`

**Files:**
- Modify: `lib/features/tenant/presentation/providers/tenant_order_provider.dart` (full rewrite)
- Test: `test/features/tenant/presentation/tenant_order_provider_test.dart` (full rewrite)

**Interfaces:**
- Consumes: `TenantOrderRepository`/`tenantOrderRepositoryProvider` (Task 9), `TenantRealtimeService`/`tenantRealtimeServiceProvider`/`FakeTenantRealtimeService` (Task 6/7), `localStorageProvider`/`tenantBranchIdStorageKey` (Task 2).
- Produces: `tenantOrderBoardProvider` now exposes `AsyncValue<List<TenantOrder>>` (was a plain synchronous `List<IncomingOrderData>`); `accept`/`reject`/`markReady` are now `Future<void>` and rethrow on failure after reverting the optimistic update.

- [ ] **Step 1: Write the failing tests (full replacement)**

Replace the entire contents of `test/features/tenant/presentation/tenant_order_provider_test.dart`:

```dart
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/storage/local_storage.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_order_repository.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_order_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/canned_dio.dart';
import '../../../support/fake_local_storage.dart';
import '../../../support/fake_tenant_realtime_service.dart';

Map<String, dynamic> _orderJson({
  required String id,
  required String status,
  int? broadcastEventId,
}) =>
    {
      'id': id,
      'order_group_id': 'group-$id',
      'branch_id': 'branch-1',
      'receipt_number': 'RCP-$id',
      'grand_total': 21000,
      'order_status': status,
      'created_at': '2026-08-07 09:24:08',
      'updated_at': '2026-08-07 09:24:08',
      'items': <dynamic>[],
      if (broadcastEventId != null) 'broadcast_event_id': broadcastEventId,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLocalStorage storage;
  late FakeTenantRealtimeService realtime;
  late TenantOrderRepository repository;
  late ProviderContainer container;

  ProviderContainer buildContainer({required int statusCode, required Object? body}) {
    storage = FakeLocalStorage()..values[tenantBranchIdStorageKey] = 'branch-1';
    realtime = FakeTenantRealtimeService();
    repository = TenantOrderRepository(dio: cannedDio(statusCode, body));
    final c = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        tenantOrderRepositoryProvider.overrideWithValue(repository),
        tenantRealtimeServiceProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(c.dispose);
    addTearDown(realtime.close);
    return c;
  }

  Object? _listBody(List<Map<String, dynamic>> orders) => {
        'meta': {'success': true, 'message': 'Success', 'code': 200, 'trace_id': 'abc'},
        'data': orders,
      };

  group('initial load', () {
    test('fetches once using the stored branch id', () async {
      container = buildContainer(
        statusCode: 200,
        body: _listBody([_orderJson(id: '1', status: 'PENDING')]),
      );

      final orders = await container.read(tenantOrderBoardProvider.future);

      expect(orders, hasLength(1));
      expect(orders.single.id, '1');
    });

    test('surfaces a fetch failure as AsyncError', () async {
      container = buildContainer(
        statusCode: 500,
        body: {'meta': {'success': false, 'message': 'Error', 'code': 500, 'trace_id': 'abc'}},
      );

      await expectLater(
        container.read(tenantOrderBoardProvider.future),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('realtime new-order delivery', () {
    test('an order.created event appends to the board', () async {
      container = buildContainer(
        statusCode: 200,
        body: _listBody([_orderJson(id: '1', status: 'PENDING')]),
      );
      await container.read(tenantOrderBoardProvider.future);

      realtime.emitOrderCreated(_orderJson(id: '2', status: 'PENDING'));
      await Future<void>.delayed(Duration.zero);

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders.map((o) => o.id), containsAll(['1', '2']));
    });

    test('a duplicate order id from the stream does not double the list',
        () async {
      container = buildContainer(
        statusCode: 200,
        body: _listBody([_orderJson(id: '1', status: 'PENDING')]),
      );
      await container.read(tenantOrderBoardProvider.future);

      realtime.emitOrderCreated(_orderJson(id: '1', status: 'PENDING'));
      await Future<void>.delayed(Duration.zero);

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders, hasLength(1));
    });
  });

  group('accept / reject / markReady', () {
    test('accept optimistically moves an order to preparing then confirms',
        () async {
      container = buildContainer(
        statusCode: 200,
        body: _listBody([_orderJson(id: '1', status: 'PENDING')]),
      );
      await container.read(tenantOrderBoardProvider.future);

      await container.read(tenantOrderBoardProvider.notifier).accept('1');

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders.single.status, TenantOrderStatus.preparing);
    });

    test('markReady moves a preparing order to ready', () async {
      container = buildContainer(
        statusCode: 200,
        body: _listBody([_orderJson(id: '1', status: 'PREPARING')]),
      );
      await container.read(tenantOrderBoardProvider.future);

      await container.read(tenantOrderBoardProvider.notifier).markReady('1');

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders.single.status, TenantOrderStatus.ready);
    });

    test('reject removes the order from the board (cancelled orders are not shown)',
        () async {
      container = buildContainer(
        statusCode: 200,
        body: _listBody([_orderJson(id: '1', status: 'PENDING')]),
      );
      await container.read(tenantOrderBoardProvider.future);

      await container.read(tenantOrderBoardProvider.notifier).reject(
            '1',
            reason: 'Stok Habis',
          );

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders, isEmpty);
    });

    test('reject reverts (order reappears) and rethrows on API failure',
        () async {
      storage = FakeLocalStorage()..values[tenantBranchIdStorageKey] = 'branch-1';
      realtime = FakeTenantRealtimeService();
      addTearDown(realtime.close);
      final fetchDio = cannedDio(
        200,
        _listBody([_orderJson(id: '1', status: 'PENDING')]),
      );
      final failingRepository = _FailingUpdateRepository(dio: fetchDio);
      container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          tenantOrderRepositoryProvider.overrideWithValue(failingRepository),
          tenantRealtimeServiceProvider.overrideWithValue(realtime),
        ],
      );
      addTearDown(container.dispose);
      await container.read(tenantOrderBoardProvider.future);

      await expectLater(
        container.read(tenantOrderBoardProvider.notifier).reject('1', reason: 'Stok Habis'),
        throwsA(isA<ApiException>()),
      );

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders, hasLength(1));
      expect(orders.single.status, TenantOrderStatus.pending);
    });

    test('accept reverts the optimistic change and rethrows on API failure',
        () async {
      storage = FakeLocalStorage()..values[tenantBranchIdStorageKey] = 'branch-1';
      realtime = FakeTenantRealtimeService();
      addTearDown(realtime.close);
      // First call (initial fetch) succeeds via one Dio instance; the
      // updateStatus call needs a *different* Dio wired to fail, so this
      // test builds the repository directly instead of via buildContainer.
      final fetchDio = cannedDio(
        200,
        _listBody([_orderJson(id: '1', status: 'PENDING')]),
      );
      final failingRepository = _FailingUpdateRepository(dio: fetchDio);
      container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          tenantOrderRepositoryProvider.overrideWithValue(failingRepository),
          tenantRealtimeServiceProvider.overrideWithValue(realtime),
        ],
      );
      addTearDown(container.dispose);
      await container.read(tenantOrderBoardProvider.future);

      await expectLater(
        container.read(tenantOrderBoardProvider.notifier).accept('1'),
        throwsA(isA<ApiException>()),
      );

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders.single.status, TenantOrderStatus.pending);
    });
  });
}

/// A repository whose [fetchOrders] delegates to a real (canned) [Dio] but
/// whose [updateStatus] always fails, so the rollback path can be tested in
/// isolation.
class _FailingUpdateRepository implements TenantOrderRepository {
  _FailingUpdateRepository({required Dio dio}) : _delegate = TenantOrderRepository(dio: dio);

  final TenantOrderRepository _delegate;

  @override
  Future<List<TenantOrder>> fetchOrders({required String branchId}) =>
      _delegate.fetchOrders(branchId: branchId);

  @override
  Future<void> updateStatus(String orderId, {required TenantOrderStatus status, String? reason}) {
    throw ApiException(message: 'Terjadi kesalahan. Coba lagi.');
  }

  @override
  Future<List<TenantOrder>> fetchMissedEvents({required String branchId, required int afterId}) =>
      _delegate.fetchMissedEvents(branchId: branchId, afterId: afterId);
}
```

Note: `_FailingUpdateRepository implements TenantOrderRepository` requires `TenantOrderRepository` to not be `final`/`sealed` — it already isn't (Task 9 wrote a plain class), so this compiles as-is; no change needed to Task 9's file. Add `import 'package:dio/dio.dart';` to the test file for the `Dio` type used in `_FailingUpdateRepository`.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/tenant/presentation/tenant_order_provider_test.dart`
Expected: FAIL (compile errors — `tenantOrderBoardProvider` is still the old sync mock).

- [ ] **Step 3: Rewrite `lib/features/tenant/presentation/providers/tenant_order_provider.dart`**

```dart
import 'dart:async';

import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/core/storage/local_storage.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_order_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tenant_order_provider.g.dart';

/// The tenant "Order" board: fetches once from the real API, then stays
/// live via [TenantRealtimeService.orderCreated] — no polling. [accept],
/// [reject] and [markReady] optimistically update local state, call the
/// repository, and revert-and-rethrow on failure so the screen can show an
/// error (see `TenantOrderScreen`).
@riverpod
class TenantOrderBoard extends _$TenantOrderBoard {
  StreamSubscription<Map<String, dynamic>>? _orderCreatedSubscription;
  StreamSubscription<void>? _reconnectedSubscription;
  int? _lastBroadcastEventId;
  late String _branchId;

  @override
  Future<List<TenantOrder>> build() async {
    final branchId = await ref.read(localStorageProvider).read(tenantBranchIdStorageKey);
    if (branchId == null) {
      throw StateError('TenantOrderBoard requires a tenant-scoped session');
    }
    _branchId = branchId;

    final repository = ref.watch(tenantOrderRepositoryProvider);
    final realtime = ref.watch(tenantRealtimeServiceProvider);

    ref.onDispose(() {
      _orderCreatedSubscription?.cancel();
      _reconnectedSubscription?.cancel();
    });

    _orderCreatedSubscription = realtime.orderCreated.listen(_onOrderCreated);
    _reconnectedSubscription = realtime.reconnected.listen((_) => _onReconnected(repository));

    final orders = await repository.fetchOrders(branchId: branchId);
    _trackBroadcastEventId(orders);
    return _excludeCancelled(orders);
  }

  void _onOrderCreated(Map<String, dynamic> payload) {
    final order = TenantOrder.fromJson(payload);
    final current = state.value;
    if (current == null) return;
    if (current.any((o) => o.id == order.id)) return;
    _trackBroadcastEventId([order]);
    state = AsyncData([order, ...current]);
  }

  Future<void> _onReconnected(TenantOrderRepository repository) async {
    final afterId = _lastBroadcastEventId;
    if (afterId == null) return;
    final missed = await repository.fetchMissedEvents(
      branchId: _branchId,
      afterId: afterId,
    );
    final current = state.value;
    if (current == null || missed.isEmpty) return;
    final currentIds = current.map((o) => o.id).toSet();
    final fresh = missed.where((o) => !currentIds.contains(o.id));
    _trackBroadcastEventId(missed);
    state = AsyncData([...fresh, ...current]);
  }

  void _trackBroadcastEventId(List<TenantOrder> orders) {
    for (final order in orders) {
      final id = order.broadcastEventId;
      if (id != null && (_lastBroadcastEventId == null || id > _lastBroadcastEventId!)) {
        _lastBroadcastEventId = id;
      }
    }
  }

  List<TenantOrder> _excludeCancelled(List<TenantOrder> orders) =>
      orders.where((o) => o.status != TenantOrderStatus.cancelled).toList();

  Future<void> accept(String orderId) => _transition(orderId, TenantOrderStatus.preparing);

  Future<void> markReady(String orderId) => _transition(orderId, TenantOrderStatus.ready);

  Future<void> reject(
    String orderId, {
    required String reason,
    List<String>? rejectedItemNames,
  }) =>
      // rejectedItemNames is UI-only for now (open follow-up: whether the
      // API supports partial-item rejection) — not sent to the backend.
      _transition(orderId, TenantOrderStatus.cancelled, reason: reason);

  Future<void> _transition(
    String orderId,
    TenantOrderStatus target, {
    String? reason,
  }) async {
    final current = state.value;
    if (current == null) return;
    final index = current.indexWhere((o) => o.id == orderId);
    if (index == -1) return;
    final previous = current[index];

    // A cancelled order is excluded from the board entirely (see
    // `incomingOrderStatusFromBackend`, which deliberately throws for
    // `cancelled` — it must never reach the mapper), so "reject" removes
    // the row instead of updating it in place like accept/markReady do.
    final optimistic = target == TenantOrderStatus.cancelled
        ? [for (final o in current) if (o.id != orderId) o]
        : [
            for (final o in current)
              if (o.id == orderId) previous.copyWith(status: target) else o,
          ];
    state = AsyncData(optimistic);

    try {
      await ref.read(tenantOrderRepositoryProvider).updateStatus(
            orderId,
            status: target,
            reason: reason,
          );
    } catch (error) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
```

- [ ] **Step 4: Generate Riverpod code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `tenant_order_provider.g.dart` regenerates with no errors.

- [ ] **Step 5: Run the tests again — confirm they pass**

Run: `flutter test test/features/tenant/presentation/tenant_order_provider_test.dart`
Expected: PASS (9 tests).

- [ ] **Step 6: Run analyzer, commit**

```bash
flutter analyze
git add lib/features/tenant/presentation/providers/tenant_order_provider.dart lib/features/tenant/presentation/providers/tenant_order_provider.g.dart test/features/tenant/presentation/tenant_order_provider_test.dart
git commit -m "feat(tenant): rewrite TenantOrderBoard as a real, realtime-fed AsyncNotifier"
```

---

## Task 11: Update the tenant order screens to consume the real board

**Files:**
- Modify: `lib/features/tenant/presentation/screens/tenant_order_screen.dart`
- Modify: `lib/features/tenant/presentation/screens/tenant_reject_order_screen.dart:132-152`
- Test: `test/features/tenant/presentation/tenant_order_screen_test.dart`
- Test: `test/features/tenant/presentation/tenant_reject_order_screen_test.dart`
- Regenerate (if needed): `test/features/tenant/presentation/tenant_order_screen_golden_test.dart`, `tenant_reject_order_screen_golden_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 8-10.
- Produces: no new public interface — UI adaptation only.

- [ ] **Step 1: Update `tenant_order_screen_test.dart`'s pump helper to override the new providers**

Replace `test/features/tenant/presentation/tenant_order_screen_test.dart` in full:

```dart
import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/storage/local_storage.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_order_repository.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_order_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/canned_dio.dart';
import '../../../support/fake_local_storage.dart';
import '../../../support/fake_tenant_realtime_service.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';

Map<String, dynamic> _orderJson({required String id, required String status}) => {
      'id': id,
      'order_group_id': 'group-$id',
      'branch_id': 'branch-1',
      'receipt_number': 'RCP-$id',
      'grand_total': 21000,
      'order_status': status,
      'created_at': '2026-08-07 09:24:08',
      'updated_at': '2026-08-07 09:24:08',
      'items': <dynamic>[],
    };

/// Pumps [TenantOrderScreen] inside a minimal router, with the order board
/// backed by a fake repository seeded with 2 pending, 1 preparing, 1 ready
/// order (matching the old mock's Baru/Diproses/Selesai split) so the
/// existing sub-tab assertions stay meaningful.
Future<void> _pumpScreen(
  WidgetTester tester, {
  IncomingOrderStatus initialStatus = IncomingOrderStatus.baru,
}) async {
  final storage = FakeLocalStorage()..values[tenantBranchIdStorageKey] = 'branch-1';
  final dio = cannedDio(200, {
    'meta': {'success': true, 'message': 'Success', 'code': 200, 'trace_id': 'abc'},
    'data': [
      _orderJson(id: '1', status: 'PENDING'),
      _orderJson(id: '2', status: 'PENDING'),
      _orderJson(id: '3', status: 'PREPARING'),
      _orderJson(id: '4', status: 'READY'),
    ],
  });

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => TenantOrderScreen(initialStatus: initialStatus),
      ),
      GoRoute(
        path: '/ditolak',
        name: TenantRoutes.pesananDitolak,
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        tenantOrderRepositoryProvider.overrideWithValue(TenantOrderRepository(dio: dio)),
        tenantRealtimeServiceProvider.overrideWithValue(FakeTenantRealtimeService()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('TenantOrderScreen in-place status sub-filtering', () {
    testWidgets('starts on Order Baru and lists only baru orders', (tester) async {
      await _pumpScreen(tester);

      expect(find.byType(IncomingOrderCard), findsNWidgets(2));
      expect(find.text('Terima (29s)'), findsNWidgets(2));
      expect(find.text('Tolak'), findsNWidgets(2));
      expect(find.text('RCP-1'), findsOneWidget);
      expect(find.text('RCP-2'), findsOneWidget);
      expect(find.text('Siap Diambil'), findsNothing);
    });

    testWidgets('tapping Diproses switches the list in place', (tester) async {
      await _pumpScreen(tester);

      await tester.tap(find.text('Diproses'));
      await tester.pumpAndSettle();

      expect(find.byType(IncomingOrderCard), findsOneWidget);
      expect(find.text('Siap Diambil'), findsOneWidget);
      expect(find.text('Terima (29s)'), findsNothing);
    });

    testWidgets('tapping Selesai shows completed orders with no actions',
        (tester) async {
      await _pumpScreen(tester);

      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(find.byType(IncomingOrderCard), findsOneWidget);
      expect(find.text('Siap Diambil'), findsNothing);
      expect(find.text('Terima (29s)'), findsNothing);
      expect(find.text('Tolak'), findsNothing);
    });

    testWidgets('initialStatus seeds the diproses sub-tab (menu-diproses)',
        (tester) async {
      await _pumpScreen(tester, initialStatus: IncomingOrderStatus.diproses);

      expect(find.text('Siap Diambil'), findsOneWidget);
      expect(find.text('Terima (29s)'), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run the screen test to verify it fails**

Run: `flutter test test/features/tenant/presentation/tenant_order_screen_test.dart`
Expected: FAIL — `TenantOrderScreen` still reads the old sync `List<IncomingOrderData>` provider directly; `'Meja A-12'`-style text is gone so even a compiling-but-unupdated screen would fail these new assertions.

- [ ] **Step 3: Update `TenantOrderScreen`**

In `lib/features/tenant/presentation/screens/tenant_order_screen.dart`:

Add imports:
```dart
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
```

Replace the `build` method's board-reading lines and the `_OrderList` callbacks. The new `build`:

```dart
  @override
  Widget build(BuildContext context) {
    final boardAsync = ref.watch(tenantOrderBoardProvider);
    final status = _statuses[_selected];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TenantOrderHeader(tenantName: 'KFC\nFried Chicken'),
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -12, 0),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              clipBehavior: Clip.antiAlias,
              child: boardAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    error is ApiException ? error.message : 'Terjadi kesalahan. Coba lagi.',
                  ),
                ),
                data: (board) => _buildBoard(context, board, status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard(
    BuildContext context,
    List<TenantOrder> board,
    IncomingOrderStatus status,
  ) {
    final data = board.map((o) => o.toIncomingOrderData()).toList();
    final orders = data.where((o) => o.status == status).toList(growable: false);
    final baruCount = _countFor(data, IncomingOrderStatus.baru);
    final diprosesCount = _countFor(data, IncomingOrderStatus.diproses);

    return Column(
      children: [
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedTabBar(
            selectedIndex: _selected,
            onChanged: (i) => setState(() => _selected = i),
            items: [
              SegmentedTabItem(
                label: 'Order Baru',
                badge: baruCount == 0
                    ? null
                    : OrderTabBadge(count: baruCount, color: AppColors.orderBadgeRed),
              ),
              SegmentedTabItem(
                label: 'Diproses',
                badge: diprosesCount == 0
                    ? null
                    : OrderTabBadge(count: diprosesCount, color: AppColors.orderBadgeAmber),
              ),
              const SegmentedTabItem(label: 'Selesai'),
            ],
          ),
        ),
        Expanded(
          child: orders.isEmpty
              ? const _EmptyOrders()
              : _OrderList(
                  orders: orders,
                  onAccept: (order) => _runAction(
                    context,
                    () => ref.read(tenantOrderBoardProvider.notifier).accept(order.orderId),
                  ),
                  onPickupReady: (order) => _runAction(
                    context,
                    () => ref.read(tenantOrderBoardProvider.notifier).markReady(order.orderId),
                  ),
                  onReject: (order) => context.goNamed(TenantRoutes.pesananDitolak),
                  onOpenDetail: (order) => context.goNamed(TenantRoutes.orderDetail),
                ),
        ),
      ],
    );
  }

  Future<void> _runAction(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is ApiException ? error.message : 'Terjadi kesalahan. Coba lagi.'),
        ),
      );
    }
  }
```

Remove the old `_countFor` signature's dependency on `List<IncomingOrderData>` being the board type directly — it already takes `List<IncomingOrderData>`, which now receives `data` (the mapped list) instead of `board`, so its signature is unchanged; only call sites moved into `_buildBoard`.

- [ ] **Step 4: Run the screen test again — confirm it passes**

Run: `flutter test test/features/tenant/presentation/tenant_order_screen_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Update `TenantRejectOrderScreen._confirm`**

In `lib/features/tenant/presentation/screens/tenant_reject_order_screen.dart`, add the import `import 'package:dtw_app/core/exceptions.dart';` and replace `_confirm`:

```dart
  Future<void> _confirm() async {
    final rejectedNames =
        _lines.where((l) => !l.available).map((l) => l.name).toList();
    final reason = _lines
        .firstWhere((l) => !l.available, orElse: () => _lines.first)
        .reason;

    try {
      await ref.read(tenantOrderBoardProvider.notifier).reject(
            widget.orderId,
            reason: reason ?? '',
            rejectedItemNames: rejectedNames,
          );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is ApiException ? error.message : 'Terjadi kesalahan. Coba lagi.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    await showRejectConfirmedModal(
      context,
      acceptedCount: _availableCount,
      rejectedCount: _rejectedCount,
      acceptedTotal: formatRupiah(_acceptedTotal),
      onConfirm: () => context.goNamed(TenantRoutes.pesananDiproses),
    );
  }
```

- [ ] **Step 6: Update `tenant_reject_order_screen_test.dart`'s pump helper**

In `test/features/tenant/presentation/tenant_reject_order_screen_test.dart`, add the same provider overrides used in Task 11 Step 1's `_pumpScreen` (fake local storage with a branch id, a real `TenantOrderRepository` wired to a `cannedDio` seeded with an order whose `id` is `'92842'` — matching the screen's hard-coded `widget.orderId` default used by `TenantRejectOrderScreen()`'s existing tests — and a `FakeTenantRealtimeService`). Update `_pump`:

```dart
import 'package:dtw_app/core/storage/local_storage.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_order_repository.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
// (add alongside the existing imports)

import '../../../support/canned_dio.dart';
import '../../../support/fake_local_storage.dart';
import '../../../support/fake_tenant_realtime_service.dart';

Future<GoRouter> _pump(WidgetTester tester, {Widget? screen}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final storage = FakeLocalStorage()..values[tenantBranchIdStorageKey] = 'branch-1';
  final dio = cannedDio(200, {
    'meta': {'success': true, 'message': 'Success', 'code': 200, 'trace_id': 'abc'},
    'data': [
      {
        'id': '92842',
        'order_group_id': 'group-92842',
        'branch_id': 'branch-1',
        'receipt_number': 'RCP-92842',
        'grand_total': 40000,
        'order_status': 'PENDING',
        'created_at': '2026-08-07 09:24:08',
        'updated_at': '2026-08-07 09:24:08',
        'items': <dynamic>[],
      },
    ],
  });

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => screen ?? const TenantRejectOrderScreen(),
      ),
      GoRoute(
        path: '/diproses',
        name: TenantRoutes.pesananDiproses,
        builder: (context, state) =>
            const TenantOrderScreen(initialStatus: IncomingOrderStatus.diproses),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        tenantOrderRepositoryProvider.overrideWithValue(TenantOrderRepository(dio: dio)),
        tenantRealtimeServiceProvider.overrideWithValue(FakeTenantRealtimeService()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
```

The rest of the test file's assertions (`'#92842'`, item names, totals) come from `TenantRejectOrderScreen`'s own widget-local mock data (unaffected by this plan — it doesn't read `tenantOrderBoardProvider` for its item list, only calls `.reject()` on it), so they don't need to change.

- [ ] **Step 7: Run the reject-screen tests — confirm they pass**

Run: `flutter test test/features/tenant/presentation/tenant_reject_order_screen_test.dart`
Expected: PASS (5 tests, including the `formatRupiah` one from Task 8).

- [ ] **Step 8: Regenerate golden tests if they fail**

Run: `flutter test test/features/tenant/presentation/tenant_order_screen_golden_test.dart test/features/tenant/presentation/tenant_reject_order_screen_golden_test.dart`

If either fails on pixel diff (expected — `RCP-1`/`RCP-2` text differs from the old `Meja A-12`/`Meja A-14` mock text, changing rendered width), regenerate:

Run: `flutter test --update-goldens test/features/tenant/presentation/tenant_order_screen_golden_test.dart test/features/tenant/presentation/tenant_reject_order_screen_golden_test.dart`

Then open the updated `.png` files under each test's `goldens/` directory and visually confirm the layout still looks correct (no overflow, no clipped text) before committing them.

- [ ] **Step 9: Run the full test suite + analyzer**

Run: `flutter test` then `flutter analyze`
Expected: PASS, zero new warnings.

- [ ] **Step 10: Commit**

```bash
git add lib/features/tenant/presentation/screens/tenant_order_screen.dart lib/features/tenant/presentation/screens/tenant_reject_order_screen.dart test/features/tenant/presentation/tenant_order_screen_test.dart test/features/tenant/presentation/tenant_reject_order_screen_test.dart test/features/tenant/presentation/tenant_order_screen_golden_test.dart test/features/tenant/presentation/tenant_reject_order_screen_golden_test.dart
git commit -m "feat(tenant): wire the order screens to the real, realtime-fed board"
```

---

## Task 12: Manual end-to-end verification

**Files:** none (no code changes — verification only).

- [ ] **Step 1: Run the full test suite one final time**

Run: `flutter test`
Expected: PASS, all tests (auth + tenant + everything else untouched).

- [ ] **Step 2: Run on a connected Android device with real tenant credentials**

Run: `flutter run -d <device-id> -t lib/main_dev.dart`, then log in with `janji_jiwa_smlb` / `password` (the same real test account used throughout this plan's research).

Expected: lands on the tenant Order shell (not busboy), the Order Baru tab shows whatever real orders exist for that branch (likely the one `RCP-20260807-IOOXVF` seen during research, table-name slot showing the receipt number instead of a real table — this is the known, accepted gap).

- [ ] **Step 3: Confirm the Reverb connection**

While the app is running, check the `flutter run` console output for `ReverbTenantRealtimeService` connection errors (a failed `authEndpoint` handshake or a wrong port would show up as a Dio/socket error in the log). If it fails to connect, per Task 5 Step 3's note, the assumed port 443 is likely wrong — get the real Reverb port from the backend team and update `ReverbConfig.port`.

- [ ] **Step 4: If reachable, place a real test order against branch `0bac8a76-dd70-4345-9d16-742c585e676a` and confirm it appears on the Order Baru tab within a second or two, with no manual refresh.**

This is the actual product acceptance check for this whole plan — the rest of Task 12 (and every automated test before it) verifies the mechanism; this step verifies the outcome the user asked for.

- [ ] **Step 5: Tap Terima on a real order, confirm it moves to the Diproses tab and the API call succeeded (check the `flutter run` log for the PATCH request/response).**

If the PATCH fails with a validation error, that confirms the Task 9 open item (the `order_status`/`reason` body shape) needs adjusting — fix `TenantOrderRepository.updateStatus` based on the real error message, add a regression test for the corrected shape, and commit as a follow-up fix (not a new spec — this was flagged as expected risk).

- [ ] **Step 6: No commit for this task** — it's verification, not code. If Step 5 or Step 3 uncovered a real fix, that fix gets its own focused commit at the point it's made.

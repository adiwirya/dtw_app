# Real Login Integration — Busboy (Riverpod/go_router) Design

Date: 2026-08-09
Status: Approved for implementation planning

## Context

This resolves **Open Question 1** from `ai_specs/0001-busboy-order-app/spec.md`
("Auth: login endpoint, token storage, 'Ingat Saya' persistence; is the Tenan
role in scope for this busboy build?"), left deliberately deferred when the
busboy UI (17 frames + routing shell) was built with mock data and stubbed
Riverpod providers.

`dtw_app` (this codebase — `github.com/adiwirya/dtw_app`, branch
`feat/busboy-order-app`) is a single Flutter binary covering both the
**busboy** (staff/POS) and **tenant** (customer-facing) product experiences,
picked at runtime via `appFlavorProvider` (`lib/core/flavor.dart`) rather than
build-time flavors. State management is Riverpod (`flutter_riverpod` +
`riverpod_annotation`/`riverpod_generator`), routing is `go_router`
(`StatefulShellRoute.indexedStack` per flavor router), networking is a plain
`Dio` via `@riverpod Dio dio(Ref ref)` (`lib/core/network/dio_provider.dart`).
This is architecturally unrelated to an earlier GetX-based prototype built
against a different (GitLab-hosted) scaffold repo — that work is stashed for
reference only and does not inform this design beyond the already-studied
Downtown CMS API shape.

**Backend** (Downtown CMS / DT POS — see memory `dtw-cms-api-structure`):
`POST /v1/auth/login` with `method: "password"` (CMS/staff, 8h session) or
`method: "card"` (NFC tap, 30d session, tenant — out of scope, see below).
Bearer token auth (`Authorization: Bearer <token>`) on all non-storefront
routes. Response envelope `{meta, data}` on success, `{meta, errors}` on
422/401.

**Existing UI** (`lib/features/auth/presentation/screens/login_screen.dart`),
built pixel-perfect from Figma, is a two-step shared entry point:
`/login` (role picker) → `/login/tenant` (role pre-selected + username/
password form + "Ingat Saya" checkbox + "Lupa Password?" link, no
destination). `_onMasuk()` is an explicit stub: no validation, no network
call — it just flips `isLoggedInProvider` and sets `appFlavorProvider` from
the tapped role. `TenantLoginScreen` is a near-duplicate for the tenant
flavor's own router.

**Supporting infra is also unfinished:** `LocalStorage` (`lib/core/storage/
local_storage.dart`) is an abstract interface with no concrete
implementation; `dioProvider` has no auth header, no error interceptor;
`isLoggedInProvider`/`appFlavorProvider` are plain in-memory `StateProvider`s
with no persistence.

## Scope

**In scope (this spec):**
- Real password-based login for the **Busboy** role path of the shared
  `LoginScreen`, calling the real Downtown CMS API.
- A concrete `LocalStorage` implementation (secure) and session persistence
  across app restarts.
- A reactive router guard so session expiry (401) actually redirects to
  `/login`, not just at first launch.
- Wiring the Akun screen's "Keluar" action to a real logout.

**Out of scope (future spec):**
- Tenant NFC/card login. The eventual product direction splits this shared
  role-picker screen into two dedicated UIs — busboy (password) and tenant
  (NFC card) — per user decision; `TenantLoginScreen` and the Tenan role path
  within `LoginScreen` are untouched by this spec and keep their current
  mock behavior (tap Masuk → flip flavor, no real auth).
- Token refresh (API has no refresh endpoint; expiry is handled by re-login).
- "Ingat Saya" as a real conditional (see Data Flow — it's UI-only for now).
- "Lupa Password?" destination.
- Backend-side role/permission validation against the tapped role card.

## Approach

Three approaches were considered:

- **A — Minimal/inline**: `LoginScreen._onMasuk` calls `ref.read(dioProvider)`
  directly, maps errors inline. Rejected — duplicates logic for logout, and
  breaks from how every other feature here keeps network/state out of
  widgets (`admin_status_provider.dart`, `akun_provider.dart`).
- **B — Fully layered**: sealed `AuthState` union, a dedicated
  `SessionManager` on top of `LocalStorage`, a standalone `Interceptor`
  class. Rejected — more ceremony than 2 endpoints + 1 flag justify; nothing
  else in this codebase (menu/order/riwayat providers) is built this heavily.
- **C — Riverpod-idiomatic thin layer (chosen)**: a plain `AuthRepository`
  class (matching the "concrete class, no interface" convention already
  used for infra pieces) wraps `dio` + `localStorage`; an `AsyncNotifier`
  `AuthController` exposes `login()`/`logout()` for the screen to watch via
  `AsyncValue`; the `Dio` interceptor and router `redirect:` close the loop
  for session expiry. This is the smallest change that fits the codebase's
  existing Riverpod patterns.

## Architecture

```
lib/
  core/
    storage/
      local_storage.dart          (existing interface, unchanged)
      secure_local_storage.dart   (new — flutter_secure_storage impl)
    network/
      dio_provider.dart           (+ auth-header + 401 interceptor)
    router/
      app_router.dart             (+ redirect guard)
      tenant_router.dart          (+ redirect guard only — no other change)
    exceptions.dart                (new — AuthException)
  features/
    auth/
      data/
        models/
          login_request.dart      (new)
          login_response.dart     (new)
      presentation/
        providers/
          auth_repository_provider.dart   (new)
          auth_controller.dart            (new, @riverpod AsyncNotifier)
        screens/
          login_screen.dart       (+ wire Busboy path to authControllerProvider)
  features/akun/
    presentation/providers/akun_provider.dart  (+ wire logoutItem tap)
  bootstrap.dart                  (async: seed isLoggedInProvider from storage)
```

`AuthRepository` is a plain class (no abstract interface) — consistent with
how `LocalStorage` is the only interface in this codebase deliberately
introduced for a swappable infra contract; `AuthRepository` has exactly one
implementation and is mocked via constructor injection / provider override
in tests, same as `SessionService`/`LoggerService` were in the earlier
(unrelated) GetX prototype.

## Components

- **`SecureLocalStorage implements LocalStorage`** — backed by
  `flutter_secure_storage` (Keychain/Keystore-encrypted). Chosen over
  `shared_preferences` (plaintext) and over `get_secure_storage` (a
  GetX-ecosystem package; this project has zero GetX dependency).
  Exposed as `@riverpod LocalStorage localStorage(Ref ref)`.
- **`dioProvider`** — base URL becomes a hardcoded constant
  (`https://dtw-cms.gadingemerald.com/api`, same for both flavors — no
  `--dart-define` needed since there is currently one environment). Gains
  an `InterceptorsWrapper`:
  - `onRequest`: attaches `Authorization: Bearer <token>` when a token is
    present (read via `ref.read(localStorageProvider)`).
  - `onError`: when `error.response?.statusCode == 401`, clears the stored
    token and sets `ref.read(isLoggedInProvider.notifier).state = false`.
- **`AuthException`** (`lib/core/exceptions.dart`): `{message, fieldErrors}`,
  `implements Exception`. Same shape as the earlier busboy design.
- **`AuthRepository`** (constructor-injected `Dio dio`, `LocalStorage
  localStorage`):
  - `Future<void> loginWithPassword({required String username, required
    String password})` — `POST /v1/auth/login` with
    `{method: "password", username, password}`; on 200, persists
    `data.access_token` via `localStorage.write(...)`. On `DioException`,
    throws a mapped `AuthException` (see Error Handling).
  - `Future<void> logout()` — best-effort `POST /v1/auth/logout` (ignores
    failure), then always `localStorage.delete(...)`.
- **`authRepositoryProvider`** — `@riverpod AuthRepository authRepository
  (Ref ref) => AuthRepository(dio: ref.watch(dioProvider), localStorage:
  ref.watch(localStorageProvider));`
- **`AuthController`** — `@riverpod class AuthController extends
  _$AuthController` (`AsyncNotifier<void>`): `build()` returns nothing
  (`null`/unit — controller is a pure action surface, no persisted state of
  its own). `Future<void> login({required String username, required String
  password})` sets `state = const AsyncLoading()`, calls the repository,
  and on success sets `ref.read(isLoggedInProvider.notifier).state = true`
  plus `ref.read(appFlavorProvider.notifier).state = AppFlavor.busboy`
  before resolving `state = const AsyncData(null)`; on failure, `state =
  AsyncError(exception, stackTrace)`. `Future<void> logout()` delegates to
  `repository.logout()` then flips `isLoggedInProvider` to `false`.

## Data flow

**Login (Busboy role only):**
1. `LoginScreen._onMasuk()`: the screen already resolves an *effective* role
   as `_selectedRole ?? LoginRole.busboy` (null/unselected defaults to
   busboy). If that effective role is `tenan`, the **Tenan** path is
   untouched — same stub as today. Otherwise (effective role is busboy,
   whether explicitly tapped or defaulted), real login triggers.
2. For the Busboy path: client-side validation (username/password
   non-empty) — reuses the existing pattern, sets a local validation message
   if empty, does not call the controller.
3. `ref.read(authControllerProvider.notifier).login(username: ..., password:
   ...)`.
4. Screen watches `ref.watch(authControllerProvider)` — `AsyncLoading` swaps
   the `PrimaryButton` for a spinner (mirroring the button's existing
   disabled-while-loading affordance); `AsyncError` renders the mapped
   message below the form (new small `Text` widget — `AppInput` itself has
   no error-slot, so this stays a single form-level message, not per-field);
   `AsyncData` — no explicit navigation call needed, since `appRouterProvider`
   already rebuilds its `initialLocation`-driving watch on `isLoggedInProvider`
   flipping true, and `AppShell`'s router swap on `appFlavorProvider` handles
   landing on the Order tab exactly as today's stub behavior does.

**Startup (session restore):** `bootstrap()` becomes `async`:
```dart
Future<void> bootstrap({List<Override> overrides = const []}) async {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = SecureLocalStorage();
  final token = await storage.read('auth_token');
  runApp(ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      isLoggedInProvider.overrideWith((ref) => token != null && token.isNotEmpty),
      ...overrides,
    ],
    child: const App(),
  ));
}
```
One secure-storage read before the first frame — no visible splash screen
needed, no restructuring of either router's synchronous `initialLocation`
logic.

**Session expiry (401 mid-use):** `dioProvider`'s interceptor clears storage
and flips `isLoggedInProvider` to `false`. Both `appRouterProvider` and
`tenantRouterProvider` gain a `redirect:` callback, reusing the same
`loggedIn` value already watched for `initialLocation` (so the provider
rebuilds — and go_router re-evaluates — whenever `isLoggedInProvider`
changes; no second `ref.watch` needed inside the closure):
```dart
@riverpod
GoRouter appRouter(Ref ref) {
  final loggedIn = ref.watch(isLoggedInProvider);
  return GoRouter(
    initialLocation: loggedIn ? AppRoutes.orderPath : AppRoutes.loginPath,
    redirect: (context, state) {
      final onLogin = state.matchedLocation == AppRoutes.loginPath ||
          state.matchedLocation.startsWith('${AppRoutes.loginPath}/');
      if (!loggedIn && !onLogin) return AppRoutes.loginPath;
      if (loggedIn && onLogin) return AppRoutes.orderPath;
      return null;
    },
    routes: [ ... ],
  );
}
```
so a 401 anywhere in the app redirects to `/login` on the next navigation
event, not only at the router's initial construction. `tenantRouterProvider`
mirrors this with `TenantRoutes.loginPath`/`TenantRoutes.orderPath`.

**Logout:** `akun_provider.dart`'s `logoutItem` tap (currently stubbed in
`akun_screen.dart`) calls `ref.read(authControllerProvider.notifier)
.logout()`. The router guard above then naturally redirects to `/login`
once `isLoggedInProvider` flips.

## Error handling

Identical mapping and Indonesian strings to the earlier (unrelated GetX
prototype) design, since they were already reviewed against the real API
shape:

| Condition | User-facing message |
|---|---|
| 422 (validation) | Concatenation of `errors` map messages (`fieldErrors` kept structured) |
| 401 | "Username atau password salah." |
| `DioExceptionType.connectionTimeout` / `connectionError` / `receiveTimeout` | "Tidak bisa terhubung ke server. Cek koneksi internet." |
| anything else | "Terjadi kesalahan. Coba lagi." |

"Ingat Saya" does **not** gate persistence — the token is always written on
success (the checkbox stays a UI-only decoration, per its existing
`TODO(open-question)`, since the API session already runs 8h regardless and
splash-less auto-login on restart is the desired default behavior).

## Testing

- `AuthRepository` unit tests (success stores token; 422 → `fieldErrors`;
  401/timeout/generic → mapped messages; `logout()` clears storage even when
  the API call throws) — using a `ProviderContainer` with a fake `Dio`
  (e.g. `DioAdapter`/a hand-rolled `HttpClientAdapter` returning canned
  responses, matching this project's no-mockito convention) and a fake
  in-memory `LocalStorage`.
- `AuthController` tests via `ProviderContainer` overriding
  `authRepositoryProvider` with a fake repository — assert `AsyncLoading` →
  `AsyncData`/`AsyncError` transitions and the `isLoggedInProvider`/
  `appFlavorProvider` side effects.
- Router `redirect:` guard tests — a minimal `GoRouter` built the same way
  `test/features/auth/presentation/login_screen_test.dart` already does,
  asserting an authenticated-but-on-`/login` case redirects to `/order` and
  vice versa.
- **Existing test updates required**: `test/features/auth/presentation/
  login_screen_test.dart` has two tests that tap "Masuk" with empty
  username/password fields and assert immediate navigation into a shell —
  this no longer happens once real validation + a real API call gate the
  Busboy path. Both get `authRepositoryProvider` overridden with a fake
  success repository and the credential fields filled in before tapping.
  The Tenan-role test (`'picking Tenan switches the whole app to the tenant
  shell'`) is unaffected — that path stays stubbed.

## Open follow-ups (not blocking this spec)

- Tenant NFC/card login — separate spec once scheduled; will introduce
  `AuthRepository.loginWithCard(cardUid)` and the redesigned split UI
  (dedicated busboy vs. tenant login screens replacing the shared
  role-picker).
- "Lupa Password?" destination — no requirement given yet.
- Sentry integration for this project — raised separately by the user
  mid-session, tracked independently of this auth spec.

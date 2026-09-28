# Device Onboarding — Design

Status: approved (functional + UI), ready for implementation plan.

## Purpose

Wire the previously-unused `POST /v1/devices/register` endpoint
(`api-auth-device-external.md`), which registers this physical Android
device (Sunmi/POS) with the backend so an admin can later assign it to a
tenant branch via the CMS. The endpoint is idempotent/upsert-by-`device_id`
and authenticated with a static `X-Device-Key` header, not a user's Bearer
token — it has nothing to do with which user logs in.

Concept: a one-time **onboarding gate** that runs before login, once per
device install. Once it succeeds, it never runs again on that install.

## Trigger & scope

- Runs on **first app launch, before login** — not tied to any user/tenant
  session. Gate sits above the existing `isLoggedInProvider` redirect in
  `app_router.dart`.
- **Android-only**, by decision — same precedent as `NewOrderAlerts`
  ("Android only, by decision") and the `Platform.isAndroid` guards already
  in `bootstrap.dart` (Sunmi printer bind, foreground services). The
  `device_id` source (`android_id: ^0.6.0`) is Android-specific, and the
  endpoint's own purpose (registering a physical Sunmi/POS terminal) is
  inherently Android. Non-Android builds treat the device as
  already-registered and never call the endpoint.
- **Blocking, no skip.** A failed registration shows an error and a retry
  button; the user cannot reach login until it succeeds. No "skip for now."

## Architecture

A new gate in the router's redirect chain, evaluated **before** the
existing login check:

```
app start
  -> bootstrap() reads deviceRegisteredStorageKey (parallel with the
     existing token/branchId/etc reads)
  -> router redirect: !deviceRegistered && !onOnboarding -> /onboarding
                       (checked first; wins over the login redirect)
  -> DeviceOnboardingScreen auto-registers on mount
  -> success: writes deviceRegisteredStorageKey, flips the provider,
     router redirect chain re-evaluates and falls through to the
     existing logged-in/login logic
  -> failure: ErrorView-style message + "Coba Lagi", re-runs on tap
```

Non-Android builds: `deviceRegisteredProvider` initializes to `true`
directly (bootstrap never calls the repository), so the gate never
triggers.

## Components

New feature folder `lib/features/device/`, mirroring the existing
feature-first structure:

- **`lib/features/device/data/repositories/device_repository.dart`**
  `DeviceRepository.register({required deviceId, required fcmToken, String? name})`
  → `POST /v1/devices/register` with header `X-Device-Key: <const>` (a
  hardcoded constant next to it, same pattern as `_baseUrl` in
  `dio_provider.dart`). Errors go through `mapDioError` with a
  `unauthorizedMessage` override (401 here means a misconfigured device
  key, not an expired session — "Konfigurasi perangkat tidak valid."
  rather than the generic "Sesi berakhir." copy). Response isn't parsed
  into a model — nothing downstream consumes `tenant_branch_id`/etc yet
  (YAGNI); success is "didn't throw."

- **`lib/features/device/data/services/device_identity.dart`**
  `DeviceIdentity` — thin, constructor-injectable wrapper (mirrors
  `PluginBusboyFcmService`'s `FirebaseMessaging?` override /
  `PluginNewOrderAlerts`'s `AudioPlayer?` override pattern):
  ```dart
  class DeviceIdentity {
    DeviceIdentity({AndroidId? androidId, FirebaseMessaging? messaging})
      : _androidId = androidId ?? AndroidId(),
        _messaging = messaging ?? FirebaseMessaging.instance;
    Future<String?> deviceId() => _androidId.getId();
    Future<String?> fcmToken() => _messaging.getToken();
  }
  ```

- **`lib/features/device/presentation/screens/device_onboarding_screen.dart`**
  `ConsumerStatefulWidget`. Auto-triggers registration in `initState`
  (mirrors the local-state async-action pattern already used in
  `tambah_menu_screen.dart`/`tambah_varian_screen.dart`, not a Riverpod
  AsyncNotifier — this is a one-shot screen action, not shared state).

- **`lib/core/storage/secure_local_storage.dart`**: new
  `deviceRegisteredStorageKey`.

- **`lib/core/flavor.dart`**: new `deviceRegisteredProvider`
  (`StateProvider<bool>`), read at bootstrap like the existing session
  providers.

- **`lib/bootstrap.dart`**: reads `deviceRegisteredStorageKey` alongside
  the existing parallel `Future.wait` reads; on non-Android, skips the
  read and overrides the provider to `true` directly.

- **`lib/core/router/app_router.dart`**: new route `AppRoutes.onboarding`
  (path `/onboarding`), sibling to the login route (root navigator, no
  shell). Redirect logic gets a new check ahead of the existing
  logged-in check.

## Data flow

1. `DeviceOnboardingScreen.initState` calls a local `_register()`:
   - `deviceId = await deviceIdentity.deviceId()` (from `android_id`)
   - `fcmToken = await deviceIdentity.fcmToken()` (from `FirebaseMessaging`,
     same call already used in `busboy_fcm_service.dart`)
   - `await deviceRepository.register(deviceId: ..., fcmToken: ..., name: null)`
     — `name` is always omitted; per the API doc it's meant to be filled in
     later by a tenant admin via the CMS, not by the device itself.
2. On success: `ref.read(localStorageProvider).write(deviceRegisteredStorageKey, 'true')`,
   then `ref.read(deviceRegisteredProvider.notifier).state = true`. The
   router's redirect re-evaluates automatically (Riverpod-driven
   `GoRouter.refreshListenable`-equivalent already wired for
   `isLoggedInProvider`) and falls through to the existing
   login/home logic.
3. On failure: local `_error` state is set, screen shows the error UI;
   tapping "Coba Lagi" re-runs step 1.

## Error handling

- Network/timeout/5xx: generic `mapDioError` message ("Tidak bisa
  terhubung ke server..." etc.), same as every other repository.
- 401 (bad/missing `X-Device-Key`): overridden message — a config bug,
  not a session issue.
- 422 (malformed `device_id`/`fcm_token` — shouldn't happen in practice
  since both come from the platform, not user input, but the repository
  still maps it rather than crashing): generic 422 field-error join,
  same as every other repository.
- `deviceId()`/`fcmToken()` returning `null` (platform quirk, e.g. FCM
  token not yet available): treated as a failure state locally (same
  error UI + retry) rather than sending a null field to the API.

## UI

Brainstormed visually (mockups in `.superpowers/brainstorm/`, not
committed — gitignored). Matches the existing forgot-password screens'
visual pattern for consistency (icon block → heading → description →
action), not a generic spinner-only splash:

**Loading state:**
- 80×80 rounded-16 icon block, `AppColors.successGreen`-tinted background
  (`#E6F7EF`), device glyph
- Heading: "Menyiapkan Device" — `AppColors.neutral900`, 16px, w700
- Description: "Mendaftarkan device ini ke server, mohon tunggu sebentar."
  — `AppColors.neutral500`, 13px
- Small circular spinner below, `AppColors.successGreen`

**Error state:** same icon block as loading (device glyph stays neutral
green — it does NOT turn red/warning), same heading position now reading
"Gagal Menyiapkan Device", description text swapped to the actual
`errorMessage(error)` result in `AppColors.dangerRed` (mirrors the
existing shared `ErrorView` widget's text-only error convention — no red
icon anywhere else in the app), and a full-width `PrimaryButton`-style
"Coba Lagi" button below.

No app bar / back button — this screen precedes login, there's nowhere to
go back to.

## Testing

- `test/features/device/data/repositories/device_repository_test.dart`
  (unit, `cannedDio`): success (200), sends the right body + `X-Device-Key`
  header, 401 bad key → mapped `ApiException` with the override message,
  422 → mapped, network failure → mapped.
- `test/features/device/presentation/screens/device_onboarding_screen_test.dart`
  (widget): auto-registers on mount and shows loading, success advances
  (via a fake `DeviceIdentity`/repository override), failure shows the
  error UI with the message, tapping "Coba Lagi" re-invokes registration.
- One router-level test (extends the existing app-router test file, or a
  small dedicated one) confirming the onboarding gate wins over the
  logged-in redirect when `deviceRegisteredProvider` is `false` regardless
  of `isLoggedInProvider`.

## Out of scope / explicitly deferred

- The `name` field is never sent by the app (admin fills it via CMS).
- No UI ever surfaces `tenant_branch_id`/branch-assignment status — that
  happens entirely out-of-band via CMS after registration.
- No re-registration on FCM token rotation — `busboy_fcm_service.dart`
  already owns token-refresh registration for logged-in busboy sessions
  via a different endpoint (`POST /busboy/fcm-token`); this is a separate,
  one-time device identity registration, not a token-freshness mechanism.
- No manual "re-run onboarding" affordance (e.g. a debug/admin menu item)
  — out of scope unless requested later.

# Device Onboarding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire `POST /v1/devices/register` as a one-time, pre-login onboarding gate: on first launch (Android only), the app registers this device (Android ID + FCM token) with the backend before the user ever sees the login screen, and never runs the gate again once it succeeds.

**Architecture:** A new `DeviceOnboardingScreen` sits behind a new router redirect gate that is checked *before* the existing logged-in gate. The gate's state (`deviceRegisteredProvider`) is read from secure storage at bootstrap (Android only — always `true` elsewhere) and flipped to `true` by the screen itself on a successful register call. `DeviceRepository` (data layer, concrete class + `cannedDio`-tested, same convention as every other repository in this app) makes the actual call; `DeviceIdentity` (an interface + `Plugin`/`Fake` pair, same convention as `BusboyFcmService`/`NewOrderAlerts`) wraps the two platform reads (`android_id`, `FirebaseMessaging.getToken()`) the repository needs.

**Tech Stack:** Flutter, Riverpod (`riverpod_annotation`/`@riverpod`), `dio`, `go_router`, `android_id: ^0.6.0`, `firebase_messaging` (already a dependency).

**Spec:** `docs/superpowers/specs/2026-09-28-device-onboarding-design.md`

## Global Constraints

- Android-only: on any non-Android platform the gate never triggers and the register endpoint is never called (`Platform.isAndroid` guard in `bootstrap.dart`, same pattern already used for `SunmiPrinter.bind()` and the foreground services there).
- `deviceRegisteredProvider` **defaults to `true`**, not `false` — only `bootstrap.dart` ever sets it `false` (a real Android device that hasn't registered yet). This is a deliberate deviation from a naive "starts false" design: 6 existing test files (`app_router_redirect_test.dart`, `app_test.dart`, `tenant_shell_test.dart`, `login_screen_test.dart`, `new_order_banner_test.dart`, `order_success_routes_test.dart`) build the real `App()`/`appRouterProvider` without knowing this provider exists; defaulting `false` would force every one of them through onboarding and fail. Defaulting `true` keeps them all passing unmodified.
- No "skip" affordance anywhere in the onboarding UI — a failure only offers "Coba Lagi", per the approved design.
- The app never sends a `name` in the register request body — that field is filled in later by a tenant admin via the CMS (per `api-auth-device-external.md`).
- Repository error handling goes through the existing `mapDioError`/`ApiException` machinery (`lib/core/exceptions.dart`) — no new exception type.
- Platform-plugin wrappers (`android_id`, `FirebaseMessaging`) are abstracted behind an interface with a `Plugin*` implementation and a `Fake*` test double in `test/support/` — the same shape as `BusboyFcmService`/`NewOrderAlerts`, not constructor-injected real plugin objects directly (a real `AudioPlayer()`/`FirebaseMessaging.instance` still touches a platform channel even just to construct, which breaks in a plain widget test with no platform binding).
- One-shot async screen actions use local `State` (`_loading`/`_error` fields), not a Riverpod `AsyncNotifier` — same convention as `tambah_menu_screen.dart`/`tambah_varian_screen.dart` and the forgot-password screens.
- Run `flutter analyze` and the task's own tests before every commit; run the full `flutter test --exclude-tags golden` once after the last task.
- **The `X-Device-Key` constant added in Task 1 is a placeholder value** (`'CHANGE_ME_DEVICE_REGISTRATION_KEY'`) — the real value is `DEVICE_REGISTRATION_KEY`, configured server-side, and neither this plan's author nor (most likely) its implementer has it. It MUST be replaced with the real value (ask whoever manages the backend config) before this ships to a real device; every register call will 401 until it is. Task 1's tests do not depend on the real value (they use a canned Dio, never a real request), so this does not block finishing the plan — it blocks shipping.

## Review Focus

- `deviceId()`/`fcmToken()` resolving to `null` (permission denied, plugin quirk) must show the error/retry UI and must never send a null field to the API — owned by Task 2's screen tests.
- A rejected `X-Device-Key` (401) must show "Konfigurasi perangkat tidak valid.", not the generic "Sesi berakhir. Silakan masuk kembali." copy used for real session expiry — owned by Task 1's repository tests.
- Tapping "Coba Lagi" after a failure must be tappable and actually re-invoke registration, not stay disabled forever — owned by Task 2's screen tests.
- The onboarding gate must win over the logged-in redirect even when a session is mid-restore (`isLoggedInProvider` already `true` from a persisted token) — otherwise a device that lost its registered flag (reinstall, cleared app data) could slip straight past onboarding — owned by Task 3's router test.
- A device that HAS registered must never be routed back to onboarding — regression-guards the "run once" contract — owned by Task 3's second router test.

---

## Task 1: DeviceRepository

**Files:**
- Create: `lib/features/device/data/repositories/device_repository.dart`
- Test: `test/features/device/data/repositories/device_repository_test.dart`

**Interfaces:**
- Consumes: `dioProvider` (`lib/core/network/dio_provider.dart`), `mapDioError`/`ApiException` (`lib/core/exceptions.dart`).
- Produces: `class DeviceRepository { const DeviceRepository({required Dio dio}); Future<void> register({required String deviceId, required String fcmToken, String? name}); }`, `@riverpod DeviceRepository deviceRepository(Ref ref)` → provider `deviceRepositoryProvider`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/device/data/repositories/device_repository_test.dart`:

```dart
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/features/device/data/repositories/device_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/canned_dio.dart';

Map<String, dynamic> _okEnvelope() => {
  'meta': {
    'success': true,
    'message': 'Device registered successfully.',
    'code': 201,
    'trace_id': 'abc',
  },
  'data': {
    'id': 'uuid-device-1',
    'tenant_branch_id': null,
    'device_id': 'SN-A1B2C3D4',
    'name': null,
    'description': null,
    'created_by': null,
    'updated_by': null,
    'created_at': '2026-09-28T00:00:00.000000Z',
    'updated_at': '2026-09-28T00:00:00.000000Z',
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('register completes without throwing on success', () async {
    final repository = DeviceRepository(dio: cannedDio(201, _okEnvelope()));

    await repository.register(deviceId: 'SN-A1B2C3D4', fcmToken: 'tok-1');
  });

  test('register sends device_id/fcm_token and the X-Device-Key header',
      () async {
    final dio = cannedDio(201, _okEnvelope());
    final repository = DeviceRepository(dio: dio);

    await repository.register(deviceId: 'SN-A1B2C3D4', fcmToken: 'tok-1');

    final lastRequest = (dio.httpClientAdapter as CannedAdapter).lastRequest;
    expect(lastRequest!.path, '/v1/devices/register');
    expect(lastRequest.data, {
      'device_id': 'SN-A1B2C3D4',
      'fcm_token': 'tok-1',
    });
    expect(lastRequest.headers['X-Device-Key'], isNotNull);
  });

  test('register omits the name key entirely when not given', () async {
    final dio = cannedDio(201, _okEnvelope());
    final repository = DeviceRepository(dio: dio);

    await repository.register(deviceId: 'SN-A1B2C3D4', fcmToken: 'tok-1');

    final lastRequest = (dio.httpClientAdapter as CannedAdapter).lastRequest;
    expect((lastRequest!.data as Map).containsKey('name'), isFalse);
  });

  test('register sends name when given', () async {
    final dio = cannedDio(201, _okEnvelope());
    final repository = DeviceRepository(dio: dio);

    await repository.register(
      deviceId: 'SN-A1B2C3D4',
      fcmToken: 'tok-1',
      name: 'Kasir Lantai 1',
    );

    final lastRequest = (dio.httpClientAdapter as CannedAdapter).lastRequest;
    expect((lastRequest!.data as Map)['name'], 'Kasir Lantai 1');
  });

  test('a 401 (bad X-Device-Key) throws with the device-specific message',
      () async {
    final repository = DeviceRepository(
      dio: cannedDio(401, {
        'meta': {
          'success': false,
          'message': 'Unauthorized',
          'code': 401,
          'trace_id': 'abc',
        },
        'errors': null,
      }),
    );

    await expectLater(
      repository.register(deviceId: 'SN-A1B2C3D4', fcmToken: 'tok-1'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Konfigurasi perangkat tidak valid.',
        ),
      ),
    );
  });

  test('a 422 throws a mapped ApiException', () async {
    final repository = DeviceRepository(
      dio: cannedDio(422, {
        'meta': {
          'success': false,
          'message': 'Validation',
          'code': 422,
          'trace_id': 'abc',
        },
        'errors': {
          'device_id': ['The device id field is required.'],
        },
      }),
    );

    await expectLater(
      repository.register(deviceId: '', fcmToken: 'tok-1'),
      throwsA(isA<ApiException>()),
    );
  });

  test('a network failure throws a mapped ApiException', () async {
    final repository = DeviceRepository(
      dio: cannedDio(500, {
        'meta': {
          'success': false,
          'message': 'Error',
          'code': 500,
          'trace_id': 'abc',
        },
      }),
    );

    await expectLater(
      repository.register(deviceId: 'SN-A1B2C3D4', fcmToken: 'tok-1'),
      throwsA(isA<ApiException>()),
    );
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/device/data/repositories/device_repository_test.dart`
Expected: FAIL — `lib/features/device/data/repositories/device_repository.dart` doesn't exist yet, so this fails to compile (import error), not just a test assertion failure. That's fine — it confirms the test file itself is wired correctly to a not-yet-existing target.

- [ ] **Step 3: Write the implementation**

Create `lib/features/device/data/repositories/device_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/network/dio_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_repository.g.dart';

/// Static key the backend expects on every `POST /v1/devices/register`
/// call's `X-Device-Key` header — configured server-side as
/// `DEVICE_REGISTRATION_KEY` (see `api-auth-device-external.md`). Every
/// device registering itself sends this same value; it is not a
/// per-session/user secret.
///
/// PLACEHOLDER — replace with the real value before this ships. Every
/// register call 401s with this value in place.
const _deviceRegistrationKey = 'CHANGE_ME_DEVICE_REGISTRATION_KEY';

class DeviceRepository {
  const DeviceRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// `POST /v1/devices/register` — idempotent/upsert by [deviceId]: a new
  /// `device_id` creates a device with no branch assignment yet (an admin
  /// assigns one later via the CMS); an existing `device_id` only has its
  /// `fcm_token`/[name] updated, never its branch assignment. [name] is
  /// omitted from the request entirely when null (server default: filled
  /// in later via the CMS, never by this device itself).
  Future<void> register({
    required String deviceId,
    required String fcmToken,
    String? name,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/v1/devices/register',
        data: {
          'device_id': deviceId,
          'fcm_token': fcmToken,
          if (name != null) 'name': name,
        },
        options: Options(headers: {'X-Device-Key': _deviceRegistrationKey}),
      );
    } on DioException catch (error) {
      throw mapDioError(
        error,
        unauthorizedMessage: (_) => 'Konfigurasi perangkat tidak valid.',
      );
    }
  }
}

@riverpod
DeviceRepository deviceRepository(Ref ref) =>
    DeviceRepository(dio: ref.watch(dioProvider));
```

- [ ] **Step 4: Generate the Riverpod code and run the tests**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Then run: `flutter test test/features/device/data/repositories/device_repository_test.dart`
Expected: PASS (all 6 tests).

- [ ] **Step 5: Analyze**

Run: `flutter analyze lib/features/device/data/repositories/device_repository.dart test/features/device/data/repositories/device_repository_test.dart`
Expected: no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/device/data/repositories/device_repository.dart lib/features/device/data/repositories/device_repository.g.dart test/features/device/data/repositories/device_repository_test.dart
git commit -m "feat(device): add DeviceRepository for POST /devices/register"
```

---

## Task 2: DeviceIdentity + DeviceOnboardingScreen

**Files:**
- Modify: `pubspec.yaml` (add `android_id: ^0.6.0`)
- Modify: `lib/core/storage/secure_local_storage.dart` (add `deviceRegisteredStorageKey`)
- Modify: `lib/core/flavor.dart` (add `deviceRegisteredProvider`)
- Create: `lib/features/device/data/services/device_identity.dart`
- Create: `test/support/fake_device_identity.dart`
- Create: `lib/features/device/presentation/screens/device_onboarding_screen.dart`
- Test: `test/features/device/presentation/screens/device_onboarding_screen_test.dart`

**Interfaces:**
- Consumes: `DeviceRepository`/`deviceRepositoryProvider` (Task 1), `localStorageProvider` (`lib/core/storage/local_storage.dart`), `errorMessage`/`ApiException` (`lib/core/exceptions.dart`), `PrimaryButton` (`lib/core/widgets/primary_button.dart`), `AppColors` (`lib/core/theme/app_theme.dart`).
- Produces: `abstract class DeviceIdentity { Future<String?> deviceId(); Future<String?> fcmToken(); }`, `class PluginDeviceIdentity implements DeviceIdentity`, `@Riverpod(keepAlive: true) DeviceIdentity deviceIdentity(Ref ref)` → provider `deviceIdentityProvider`; `class FakeDeviceIdentity implements DeviceIdentity` (test double); `const deviceRegisteredStorageKey = 'device_registered'`; `final deviceRegisteredProvider = StateProvider<bool>((ref) => true)`; `class DeviceOnboardingScreen extends ConsumerStatefulWidget`.

- [ ] **Step 1: Add the `android_id` dependency**

In `pubspec.yaml`, in the `dependencies:` block, insert alphabetically (the block is otherwise alphabetized):

```yaml
  android_id: ^0.6.0
  audioplayers: ^6.8.1
```

(`android_id` goes immediately before the existing `audioplayers: ^6.8.1` line.)

Run: `flutter pub get`
Expected: resolves successfully. If it doesn't (a real `android_id: ^0.6.0` API mismatch vs. what this plan assumed — verified against `android_id-0.5.2+1`'s source: `const AndroidId()` constructor, `Future<String?> getId()` method, no other public surface), stop and re-check the installed version's actual API before continuing — Step 4 below depends on this exact shape.

- [ ] **Step 2: Add the storage key and the gate provider**

In `lib/core/storage/secure_local_storage.dart`, add after the existing `busboyZoneIdStorageKey` constant (before the `SecureLocalStorage` class):

```dart
/// Key the one-time device-onboarding gate's result is stored under
/// (`'true'` once `POST /v1/devices/register` has succeeded on this
/// install). Android only — see `deviceRegisteredProvider` and
/// `bootstrap.dart`.
const deviceRegisteredStorageKey = 'device_registered';
```

In `lib/core/flavor.dart`, add at the end of the file:

```dart

/// Whether this device has completed the one-time device-registration
/// onboarding gate (`POST /v1/devices/register`) — see
/// `docs/superpowers/specs/2026-09-28-device-onboarding-design.md`. The
/// single merged `GoRouter` redirects to onboarding before it even looks
/// at [isLoggedInProvider].
///
/// Defaults `true` so tests/screens that don't care about onboarding
/// aren't forced through it — `bootstrap.dart` is the only call site that
/// ever sets this `false` (a real Android device that hasn't registered
/// yet). The gate is Android-only by decision, so a non-Android build
/// never sets this `false` either.
final deviceRegisteredProvider = StateProvider<bool>((ref) => true);
```

- [ ] **Step 3: Write the failing screen tests**

Create `test/support/fake_device_identity.dart`:

```dart
import 'package:dtw_app/features/device/data/services/device_identity.dart';

/// In-memory [DeviceIdentity] test double — no platform channel involved.
/// Both fields default to `null`, which drives
/// `DeviceOnboardingScreen`'s "unavailable" failure path.
class FakeDeviceIdentity implements DeviceIdentity {
  FakeDeviceIdentity({String? deviceId, String? fcmToken})
    : _deviceId = deviceId,
      _fcmToken = fcmToken;

  final String? _deviceId;
  final String? _fcmToken;

  @override
  Future<String?> deviceId() async => _deviceId;

  @override
  Future<String?> fcmToken() async => _fcmToken;
}
```

Create `test/features/device/presentation/screens/device_onboarding_screen_test.dart`:

```dart
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/device/data/repositories/device_repository.dart';
import 'package:dtw_app/features/device/data/services/device_identity.dart';
import 'package:dtw_app/features/device/presentation/screens/device_onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/canned_dio.dart';
import '../../../../support/fake_device_identity.dart';
import '../../../../support/fake_local_storage.dart';

Map<String, dynamic> _envelope(int code) => {
  'meta': {
    'success': code < 300,
    'message': code < 300 ? 'Success' : 'Error',
    'code': code,
    'trace_id': 'abc',
  },
  'data': code < 300 ? {'id': 'dev-1'} : null,
};

ProviderContainer _container({
  required DeviceIdentity identity,
  required int statusCode,
  FakeLocalStorage? storage,
}) {
  return ProviderContainer(
    overrides: [
      localStorageProvider.overrideWithValue(storage ?? FakeLocalStorage()),
      deviceIdentityProvider.overrideWithValue(identity),
      deviceRepositoryProvider.overrideWithValue(
        DeviceRepository(dio: cannedDio(statusCode, _envelope(statusCode))),
      ),
    ],
  );
}

void main() {
  testWidgets('shows the preparing-device message on first frame', (
    tester,
  ) async {
    final container = _container(
      identity: FakeDeviceIdentity(deviceId: 'dev-1', fcmToken: 'tok-1'),
      statusCode: 201,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DeviceOnboardingScreen()),
      ),
    );

    // No extra pump: `initState` sets loading state synchronously before
    // its first `await`, so `pumpWidget`'s own first frame already reflects
    // it — asserting here (before any further pump lets the async register
    // call resolve) is what makes this deterministic.
    expect(find.text('Menyiapkan Device'), findsOneWidget);
  });

  testWidgets(
    'on success, persists the registered flag and flips the provider',
    (tester) async {
      final storage = FakeLocalStorage();
      final container = _container(
        identity: FakeDeviceIdentity(deviceId: 'dev-1', fcmToken: 'tok-1'),
        statusCode: 201,
        storage: storage,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DeviceOnboardingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(deviceRegisteredProvider), isTrue);
      expect(storage.values[deviceRegisteredStorageKey], 'true');
    },
  );

  testWidgets('on failure, shows the error and a Coba Lagi retry', (
    tester,
  ) async {
    final container = _container(
      identity: FakeDeviceIdentity(deviceId: 'dev-1', fcmToken: 'tok-1'),
      statusCode: 500,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DeviceOnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gagal Menyiapkan Device'), findsOneWidget);
    expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
    expect(container.read(deviceRegisteredProvider), isFalse);
  });

  testWidgets(
    'a null deviceId/fcmToken shows the error UI without calling the API',
    (tester) async {
      final container = _container(
        identity: FakeDeviceIdentity(), // both null
        statusCode: 201, // would succeed if ever called
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DeviceOnboardingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gagal Menyiapkan Device'), findsOneWidget);
      expect(container.read(deviceRegisteredProvider), isFalse);
    },
  );

  testWidgets('tapping Coba Lagi re-runs registration', (tester) async {
    final container = _container(
      identity: FakeDeviceIdentity(deviceId: 'dev-1', fcmToken: 'tok-1'),
      statusCode: 500,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DeviceOnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Coba Lagi'), findsOneWidget);

    await tester.tap(find.text('Coba Lagi'));
    await tester.pump();

    expect(find.text('Menyiapkan Device'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run the tests to verify they fail**

Run: `flutter test test/features/device/presentation/screens/device_onboarding_screen_test.dart`
Expected: FAIL to compile — `device_identity.dart` and `device_onboarding_screen.dart` don't exist yet.

- [ ] **Step 5: Write `DeviceIdentity`**

Create `lib/features/device/data/services/device_identity.dart`:

```dart
import 'package:android_id/android_id.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_identity.g.dart';

/// This device's identity for `POST /v1/devices/register` — abstracted
/// behind an interface for the same reason `BusboyFcmService`/
/// `NewOrderAlerts` are: `android_id`/`firebase_messaging` need real
/// platform channels no widget test can load — see
/// `test/support/fake_device_identity.dart`.
abstract class DeviceIdentity {
  /// This device's Android ID (`Settings.Secure.ANDROID_ID`) —
  /// `POST /v1/devices/register`'s `device_id`. `null` off Android (the
  /// `android_id` plugin itself returns `null` there) — never reached in
  /// practice since the gate that calls this is Android-only.
  Future<String?> deviceId();

  /// This device's current FCM push token — `POST /v1/devices/register`'s
  /// `fcm_token`. Same underlying call `BusboyFcmService` uses for the
  /// logged-in-session token, but this is a separate, device-level
  /// registration with no session involved.
  Future<String?> fcmToken();
}

class PluginDeviceIdentity implements DeviceIdentity {
  PluginDeviceIdentity({AndroidId? androidId, FirebaseMessaging? messaging})
    : _androidId = androidId ?? const AndroidId(),
      _messagingOverride = messaging;

  final AndroidId _androidId;
  final FirebaseMessaging? _messagingOverride;

  // Deferred to first use for the same reason as `BusboyFcmService`'s
  // `_messaging` getter: resolving `FirebaseMessaging.instance` needs
  // `Firebase.initializeApp` to already have run.
  FirebaseMessaging get _messaging =>
      _messagingOverride ?? FirebaseMessaging.instance;

  @override
  Future<String?> deviceId() => _androidId.getId();

  @override
  Future<String?> fcmToken() => _messaging.getToken();
}

@Riverpod(keepAlive: true)
DeviceIdentity deviceIdentity(Ref ref) => PluginDeviceIdentity();
```

- [ ] **Step 6: Write `DeviceOnboardingScreen`**

Create `lib/features/device/presentation/screens/device_onboarding_screen.dart`:

```dart
import 'dart:async';

import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/storage/local_storage.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/device/data/repositories/device_repository.dart';
import 'package:dtw_app/features/device/data/services/device_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The one-time, pre-login device-onboarding gate (`POST
/// /v1/devices/register`) — see
/// `docs/superpowers/specs/2026-09-28-device-onboarding-design.md`.
///
/// Auto-registers on mount; no user input, no back navigation (there is
/// nowhere to go back to — this precedes login entirely). On success,
/// persists [deviceRegisteredStorageKey] and flips
/// [deviceRegisteredProvider], which the router's redirect reacts to. On
/// failure, shows the error message with a "Coba Lagi" retry — no skip.
class DeviceOnboardingScreen extends ConsumerStatefulWidget {
  const DeviceOnboardingScreen({super.key});

  @override
  ConsumerState<DeviceOnboardingScreen> createState() =>
      _DeviceOnboardingScreenState();
}

class _DeviceOnboardingScreenState
    extends ConsumerState<DeviceOnboardingScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_register());
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final identity = ref.read(deviceIdentityProvider);
      final deviceId = await identity.deviceId();
      final fcmToken = await identity.fcmToken();
      if (deviceId == null || fcmToken == null) {
        throw StateError('device id/fcm token unavailable');
      }
      await ref
          .read(deviceRepositoryProvider)
          .register(deviceId: deviceId, fcmToken: fcmToken);
      await ref
          .read(localStorageProvider)
          .write(deviceRegisteredStorageKey, 'true');
      if (!mounted) return;
      ref.read(deviceRegisteredProvider.notifier).state = true;
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = errorMessage(error);
      });
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final failed = _error != null;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.successTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.smartphone,
                  size: 32,
                  color: AppColors.successGreen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                failed ? 'Gagal Menyiapkan Device' : 'Menyiapkan Device',
                style: const TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error ??
                    'Mendaftarkan device ini ke server, mohon tunggu '
                        'sebentar.',
                style: TextStyle(
                  color: failed ? AppColors.dangerRed : AppColors.neutral500,
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (failed)
                PrimaryButton(
                  label: 'Coba Lagi',
                  onPressed: _loading ? null : () => unawaited(_register()),
                )
              else if (_loading)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.successGreen,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Generate Riverpod code and run the tests**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Then run: `flutter test test/features/device/presentation/screens/device_onboarding_screen_test.dart`
Expected: PASS (all 5 tests).

- [ ] **Step 8: Analyze**

Run: `flutter analyze lib/features/device lib/core/storage/secure_local_storage.dart lib/core/flavor.dart test/features/device test/support/fake_device_identity.dart`
Expected: no issues.

- [ ] **Step 9: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/storage/secure_local_storage.dart lib/core/flavor.dart lib/features/device/data/services/device_identity.dart lib/features/device/data/services/device_identity.g.dart lib/features/device/presentation/screens/device_onboarding_screen.dart test/support/fake_device_identity.dart test/features/device/presentation/screens/device_onboarding_screen_test.dart
git commit -m "feat(device): add DeviceIdentity and the device onboarding screen"
```

---

## Task 3: Router gate + bootstrap wiring

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/bootstrap.dart`
- Test: `test/core/router/device_onboarding_gate_test.dart`

**Interfaces:**
- Consumes: `deviceRegisteredProvider` (Task 2), `DeviceOnboardingScreen` (Task 2), `SecureLocalStorage`/`deviceRegisteredStorageKey` (Task 2), existing `isLoggedInProvider`/`homePathFor`/`AppRoutes`.
- Produces: `AppRoutes.onboarding` (name), `AppRoutes.onboardingPath` (`/onboarding`); the `appRouter` redirect now checks the device gate before the login gate.

- [ ] **Step 1: Write the failing router test**

Create `test/core/router/device_onboarding_gate_test.dart`:

```dart
import 'package:dtw_app/app.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/features/device/data/services/device_identity.dart';
import 'package:dtw_app/features/device/presentation/screens/device_onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/busboy_board.dart';
import '../../support/fake_device_identity.dart';

Future<void> _pumpApp(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the device-onboarding gate wins over the logged-in redirect',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          ...busboyBoardOverrides(dio: cannedDeliveryListDio([])),
          deviceRegisteredProvider.overrideWith((ref) => false),
          // Null identity -> the screen fails fast locally, with no real
          // network/platform call, and never flips the gate back to true.
          deviceIdentityProvider.overrideWithValue(FakeDeviceIdentity()),
        ],
      );
      addTearDown(container.dispose);
      container.read(isLoggedInProvider.notifier).state = true;

      await _pumpApp(tester, container);

      expect(find.byType(DeviceOnboardingScreen), findsOneWidget);
      expect(find.text('Ambil'), findsNothing);
    },
  );

  testWidgets(
    'once the device is registered, a logged-in session lands on its shell',
    (tester) async {
      final container = ProviderContainer(
        overrides: busboyBoardOverrides(dio: cannedDeliveryListDio([])),
      );
      addTearDown(container.dispose);
      container.read(isLoggedInProvider.notifier).state = true;

      await _pumpApp(tester, container);

      expect(find.text('Ambil'), findsOneWidget);
      expect(find.byType(DeviceOnboardingScreen), findsNothing);
    },
  );
}
```

- [ ] **Step 2: Run the test to verify the first case fails**

Run: `flutter test test/core/router/device_onboarding_gate_test.dart`
Expected: the second test passes already (nothing routes to onboarding yet, matching today's behavior); the first test FAILS — `find.byType(DeviceOnboardingScreen)` finds nothing because the route/gate doesn't exist yet.

- [ ] **Step 3: Add the onboarding route and gate to `app_router.dart`**

In `lib/core/router/app_router.dart`, add the import alongside the other screen imports (near the `ForgotPasswordScreen` import, alphabetically before `features/order/...`):

```dart
import 'package:dtw_app/features/device/presentation/screens/device_onboarding_screen.dart';
```

In `abstract class AppRoutes`, add a new leading section right before the existing `// --- Auth ...` comment:

```dart
  // --- Device onboarding (root navigator, precedes even login) ---
  static const onboarding = 'onboarding'; // device onboarding gate
```

Then, in the same class, add the path constant next to `loginPath`:

```dart
  static const orderPath = '/order';
  static const loginPath = '/login';
  static const onboardingPath = '/onboarding';
```

In the `appRouter` provider function, add the new watch next to the existing `loggedIn` one:

```dart
@riverpod
GoRouter appRouter(Ref ref) {
  final loggedIn = ref.watch(isLoggedInProvider);
  final deviceRegistered = ref.watch(deviceRegisteredProvider);
  final homePath = homePathFor(
    role: ref.watch(sessionRoleProvider),
    branchId: ref.watch(sessionBranchIdProvider),
  );
  return GoRouter(
    initialLocation: !deviceRegistered
        ? AppRoutes.onboardingPath
        : (loggedIn ? homePath : AppRoutes.loginPath),
    redirect: (context, state) {
      final onOnboarding =
          state.matchedLocation == AppRoutes.onboardingPath ||
          state.matchedLocation.startsWith('${AppRoutes.onboardingPath}/');
      if (!deviceRegistered && !onOnboarding) return AppRoutes.onboardingPath;
      if (deviceRegistered && onOnboarding) {
        return loggedIn ? homePath : AppRoutes.loginPath;
      }
      final onLogin =
          state.matchedLocation == AppRoutes.loginPath ||
          state.matchedLocation.startsWith('${AppRoutes.loginPath}/');
      if (!loggedIn && !onLogin) return AppRoutes.loginPath;
      if (loggedIn && onLogin) return homePath;
      return null;
    },
    observers: ref.watch(analyticsObserversProvider),
    routes: [
      // Onboarding sits OUTSIDE every shell too, ahead of login.
      GoRoute(
        path: AppRoutes.onboardingPath,
        name: AppRoutes.onboarding,
        builder: (context, state) => const DeviceOnboardingScreen(),
      ),
      // Login sits OUTSIDE both shells (root navigator, no bottom nav).
      GoRoute(
        path: AppRoutes.loginPath,
        name: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
        routes: [
          // ... existing forgot-password nested routes unchanged ...
```

(Only the parts shown change — `initialLocation`, the `deviceRegistered` watch, the `redirect` body's two new lines up top, and the new sibling `GoRoute` inside `routes: [...]`. Everything else in the function, including the entire forgot-password route subtree, stays exactly as it is.)

- [ ] **Step 4: Wire `bootstrap.dart` to read the flag (Android only)**

No new import needed: `deviceRegisteredProvider` is already in scope via the
existing `import 'package:dtw_app/core/flavor.dart';`, and
`deviceRegisteredStorageKey` via the existing
`import 'package:dtw_app/core/storage/secure_local_storage.dart';`.

Change the parallel-reads block from:

```dart
  // Seven independent keys — reading them in parallel rather than one
  // `await` at a time matters here specifically: this whole function runs
  // before `runApp()`, so this is on the critical path to the first frame,
  // and a secure-storage read's first cold hit into the Android Keystore
  // can be slow.
  const storage = SecureLocalStorage();
  final [token, branchId, zoneId, username, name, role, userId] =
      await Future.wait([
    storage.read(authTokenStorageKey),
    storage.read(tenantBranchIdStorageKey),
    storage.read(busboyZoneIdStorageKey),
    storage.read(sessionUsernameStorageKey),
    storage.read(sessionNameStorageKey),
    storage.read(sessionRoleStorageKey),
    storage.read(sessionUserIdStorageKey),
  ]);
```

to:

```dart
  // Eight independent keys — reading them in parallel rather than one
  // `await` at a time matters here specifically: this whole function runs
  // before `runApp()`, so this is on the critical path to the first frame,
  // and a secure-storage read's first cold hit into the Android Keystore
  // can be slow.
  const storage = SecureLocalStorage();
  final [token, branchId, zoneId, username, name, role, userId, deviceFlag] =
      await Future.wait([
    storage.read(authTokenStorageKey),
    storage.read(tenantBranchIdStorageKey),
    storage.read(busboyZoneIdStorageKey),
    storage.read(sessionUsernameStorageKey),
    storage.read(sessionNameStorageKey),
    storage.read(sessionRoleStorageKey),
    storage.read(sessionUserIdStorageKey),
    // The device-onboarding gate is Android-only (see
    // `deviceRegisteredProvider`) — skip the read entirely on other
    // platforms rather than pay for a Keystore hit whose result is never
    // used.
    Platform.isAndroid
        ? storage.read(deviceRegisteredStorageKey)
        : Future.value(null),
  ]);
```

Then, in the `ProviderContainer` overrides list, add next to `isLoggedInProvider`'s override:

```dart
      isLoggedInProvider.overrideWith(
        (ref) => token != null && token.isNotEmpty,
      ),
      // Android only (see `deviceRegisteredProvider`'s doc comment) — a
      // non-Android build never reads the flag above, so it's always
      // treated as already registered.
      deviceRegisteredProvider.overrideWith(
        (ref) => !Platform.isAndroid || deviceFlag == 'true',
      ),
```

- [ ] **Step 5: Run the router test to verify it passes**

Run: `flutter test test/core/router/device_onboarding_gate_test.dart`
Expected: PASS (both tests).

- [ ] **Step 6: Run the affected existing router/app tests to confirm no regression**

Run: `flutter test test/core/router/app_router_redirect_test.dart test/app_test.dart test/features/tenant/tenant_shell_test.dart test/features/auth/presentation/login_screen_test.dart test/core/notifications/new_order_banner_test.dart test/features/order/presentation/order_success_routes_test.dart --exclude-tags golden`
Expected: PASS — these six files build the real `App()`/`appRouterProvider` and don't override `deviceRegisteredProvider`, so they rely on its `true` default (Task 2, Step 2) to keep passing unmodified.

- [ ] **Step 7: Analyze**

Run: `flutter analyze lib/core/router/app_router.dart lib/bootstrap.dart test/core/router/device_onboarding_gate_test.dart`
Expected: no issues.

- [ ] **Step 8: Full regression run**

Run: `flutter test --exclude-tags golden`
Expected: PASS, with the same pre-existing 4 failures this codebase already has going into this plan (`riwayat_detail_test.dart`, two in `admin_status_screen_test.dart`, `laporan_screen_test.dart` — all confirmed pre-existing/unrelated to this feature, not something this plan's tasks should fix) and no new ones.

- [ ] **Step 9: Commit**

```bash
git add lib/core/router/app_router.dart lib/bootstrap.dart test/core/router/device_onboarding_gate_test.dart
git commit -m "feat(device): wire the onboarding gate into the router and bootstrap"
```

---

## After this plan

- Replace the placeholder `_deviceRegistrationKey` in `device_repository.dart` with the real `DEVICE_REGISTRATION_KEY` value before this reaches a real device (see Global Constraints).
- Manual/on-device verification: this plan's tests can't exercise `Platform.isAndroid` both ways in one `flutter test` run (tests run on the host OS). Confirm on a real Android build that first launch shows onboarding and a second launch after success does not; confirm an iOS build (if/when one exists) never shows it.

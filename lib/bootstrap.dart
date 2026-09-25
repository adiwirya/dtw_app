import 'dart:async';
import 'dart:io';

import 'package:dtw_app/app.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/notifications/busboy_fcm_service.dart';
import 'package:dtw_app/core/notifications/busboy_foreground_service.dart';
import 'package:dtw_app/core/notifications/tenant_foreground_service.dart';
import 'package:dtw_app/core/observability/sentry_config.dart';
import 'package:dtw_app/core/realtime/busboy_realtime_service.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sunmi_utils/sunmi_utils.dart';

/// Boots the app. [overrides] lets an entrypoint reconfigure the
/// ProviderScope without changing `App`.
Future<void> bootstrap({List<Override> overrides = const []}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Debug builds keep crashing locally but don't pollute the Crashlytics
  // dashboard with dev noise.
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );
  // Same debug-noise reasoning as Crashlytics above. Network requests (Dio,
  // which rides `dart:io HttpClient`) and screen renders are auto-traced by
  // the native SDK once enabled — no per-call instrumentation needed.
  await FirebasePerformance.instance.setPerformanceCollectionEnabled(
    !kDebugMode,
  );

  // Route every uncaught error to Crashlytics. Debug builds still print to
  // console (via the default `FlutterError.presentError` inside
  // `recordFlutterFatalError`), so local development is unaffected.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
    );
    return true;
  };

  // `SentryFlutter.init` chains onto whatever `FlutterError.onError`/
  // `PlatformDispatcher.instance.onError` are already set to (it saves the
  // previous handler and calls it after its own reporting) rather than
  // replacing them outright — initializing it after the Crashlytics wiring
  // above is what makes both services see every crash. Debug builds skip
  // sending (same dashboard-noise reasoning as Crashlytics/Performance
  // above) but still install the handler chain, so a later real crash isn't
  // silently dropped from Crashlytics either.
  await SentryFlutter.init((options) {
    options
      ..dsn = kDebugMode ? '' : SentryConfig.dsn
      ..tracesSampleRate = kDebugMode ? 0 : 0.2;
  });

  // Required once per process by `flutter_foreground_task`, regardless of
  // whether a tenant session ends up starting the service this run.
  if (Platform.isAndroid) FlutterForegroundTask.initCommunicationPort();

  // Binds the built-in printer on Sunmi devices; throws `SERVICE_NOT_FOUND`
  // on every other device, which the receipt printer doesn't need to work
  // around since printing itself already no-ops off Android — swallowed
  // here purely so a non-Sunmi device's cold start isn't slowed by it.
  if (Platform.isAndroid) unawaited(SunmiPrinter.bind().catchError((_) {}));

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

  final container = ProviderContainer(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      isLoggedInProvider.overrideWith(
        (ref) => token != null && token.isNotEmpty,
      ),
      // Restores which shell a persisted session resumes into — mirrors
      // what `AuthController.login` sets at login time, from the same
      // storage key `AuthRepository` writes it to.
      sessionUsernameProvider.overrideWith((ref) => username),
      sessionNameProvider.overrideWith((ref) => name),
      sessionRoleProvider.overrideWith((ref) => role),
      sessionBranchIdProvider.overrideWith((ref) => branchId),
      sessionZoneIdProvider.overrideWith((ref) => zoneId),
      sessionUserIdProvider.overrideWith((ref) => userId),
      ...overrides,
    ],
  );

  // Resume the realtime socket for a restored tenant session — otherwise a
  // reopened app sits logged in with a dead socket until the next explicit
  // login/logout cycle. Same fire-and-forget contract as
  // `AuthController.login`: realtime is additive to the REST fetch, so a
  // failed/slow connect here must never block the first frame.
  if (branchId != null && token != null && token.isNotEmpty) {
    unawaited(
      container
          .read(tenantRealtimeServiceProvider)
          .connect(token: token, branchId: branchId)
          .catchError((_) {}),
    );
    // Same restoration as the realtime connect above — see
    // `TenantForegroundService` and `AuthController.login`.
    unawaited(
      container
          .read(tenantForegroundServiceProvider)
          .start()
          .catchError((_) {}),
    );
  }
  if (zoneId != null && token != null && token.isNotEmpty) {
    unawaited(
      container
          .read(busboyRealtimeServiceProvider)
          .connect(token: token, zoneId: zoneId)
          .catchError((_) {}),
    );
    // Same restoration as the tenant realtime connect above — see
    // `BusboyForegroundService` and `AuthController.login`.
    unawaited(
      container
          .read(busboyForegroundServiceProvider)
          .start()
          .catchError((_) {}),
    );
    // Same restoration as above — see `BusboyFcmService`.
    unawaited(
      container.read(busboyFcmServiceProvider).initialize().catchError(
        (_) {},
      ),
    );
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const App()),
  );
}

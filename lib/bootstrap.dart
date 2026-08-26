import 'dart:async';

import 'package:dtw_app/app.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Boots the app. [overrides] lets an entrypoint reconfigure the
/// ProviderScope without changing `App`.
Future<void> bootstrap({List<Override> overrides = const []}) async {
  WidgetsFlutterBinding.ensureInitialized();

  const storage = SecureLocalStorage();
  final token = await storage.read(authTokenStorageKey);
  final branchId = await storage.read(tenantBranchIdStorageKey);

  final container = ProviderContainer(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      isLoggedInProvider.overrideWith(
        (ref) => token != null && token.isNotEmpty,
      ),
      // Restores which shell a persisted session resumes into — mirrors
      // what `AuthController.login` sets at login time, from the same
      // storage key `AuthRepository` writes it to.
      sessionBranchIdProvider.overrideWith((ref) => branchId),
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
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const App()),
  );
}

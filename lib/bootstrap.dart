import 'package:dtw_app/app.dart';
import 'package:dtw_app/core/flavor.dart';
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

  runApp(
    ProviderScope(
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
      child: const App(),
    ),
  );
}

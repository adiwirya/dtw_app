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
        isLoggedInProvider.overrideWith(
          (ref) => token != null && token.isNotEmpty,
        ),
        ...overrides,
      ],
      child: const App(),
    ),
  );
}

import 'package:dtw_app/app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Boots the app. [overrides] lets an entrypoint reconfigure the ProviderScope
/// without changing `App` — `main_tenant.dart` passes a flavor override to
/// render the tenant router. The busboy entrypoints call `bootstrap()` with no
/// overrides and behave exactly as before.
void bootstrap({List<Override> overrides = const []}) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(overrides: overrides, child: const App()));
}

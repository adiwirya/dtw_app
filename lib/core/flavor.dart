import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which product experience the app boots into.
///
/// The two flavors ship in the same binary and share `App`, the theme, and
/// `bootstrap()`; they differ only in which `GoRouter` `App` renders. The
/// default is [AppFlavor.busboy] so the existing `main_dev`/`main_prod`
/// entrypoints keep rendering the busboy router unchanged. `main_tenant.dart`
/// overrides [appFlavorProvider] with [AppFlavor.tenant].
enum AppFlavor { busboy, tenant }

/// The active flavor. Defaults to busboy; `main_tenant.dart` overrides it with
/// `appFlavorProvider.overrideWithValue(AppFlavor.tenant)` at the ProviderScope
/// so no busboy code path changes.
final appFlavorProvider = Provider<AppFlavor>((ref) => AppFlavor.busboy);

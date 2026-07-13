import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which product experience the app boots into.
///
/// The two flavors ship in the same binary and share `App`, the theme, and
/// `bootstrap()`; they differ only in which `GoRouter` `App` renders. The
/// default is [AppFlavor.busboy] so the existing `main_dev`/`main_prod`
/// entrypoints keep rendering the busboy router unchanged. `main_tenant.dart`
/// overrides [appFlavorProvider] with [AppFlavor.tenant].
///
/// While there is no dedicated tenant entrypoint wired up yet, a single build
/// picks its flavor at runtime instead: the shared login screen sets this
/// provider from the tapped role ("Tenan" -> tenant, "Busboy" -> busboy) so
/// `App` swaps to the matching router immediately after "Masuk" — see
/// [isLoggedInProvider].
enum AppFlavor { busboy, tenant }

/// The active flavor. Defaults to busboy; `main_tenant.dart` overrides it with
/// `appFlavorProvider.overrideWith((ref) => AppFlavor.tenant)` at the
/// ProviderScope so no busboy code path changes. Mutable (a [StateProvider])
/// so the login screens can flip it at runtime based on the selected role.
final appFlavorProvider = StateProvider<AppFlavor>((ref) => AppFlavor.busboy);

/// Whether the user has completed the mock login flow. Read by both routers to
/// pick their `initialLocation` (their own Order tab once true, else their
/// login route) — flipping this alongside [appFlavorProvider] is what lets
/// "Masuk" land directly on the target flavor's shell instead of that flavor's
/// own login screen.
final isLoggedInProvider = StateProvider<bool>((ref) => false);

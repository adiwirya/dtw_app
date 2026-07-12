import 'package:dtw_app/bootstrap.dart';
import 'package:dtw_app/core/flavor.dart';

/// Entrypoint for the **tenant** product flavor. Boots the same `App` as the
/// busboy entrypoints but overrides the flavor so `App` renders the tenant
/// router (4-tab shell: Order / Menu Saya / Laporan / Admin). Run with:
/// `flutter run -t lib/main_tenant.dart`.
void main() => bootstrap(
      overrides: [appFlavorProvider.overrideWithValue(AppFlavor.tenant)],
    );

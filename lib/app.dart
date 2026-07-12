import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The flavor picks which router `App` renders. Defaults to busboy, so the
    // existing entrypoints are unaffected; `main_tenant.dart` overrides the
    // flavor to render the tenant router. The other router is never watched,
    // so it is never built for the inactive flavor.
    final router = switch (ref.watch(appFlavorProvider)) {
      AppFlavor.busboy => ref.watch(appRouterProvider),
      AppFlavor.tenant => ref.watch(tenantRouterProvider),
    };
    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
    );
  }
}

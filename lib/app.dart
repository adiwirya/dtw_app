import 'package:dtw_app/core/notifications/new_delivery_alert_controller.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/new_order_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the busboy new-delivery chime/notification listener alive for
    // the app's lifetime — it has no banner UI to ride along with (unlike
    // `NewOrderBannerOverlay` below), so it needs this explicit watch point
    // instead.
    ref.watch(newDeliveryAlertProvider);
    return MaterialApp.router(
      routerConfig: ref.watch(appRouterProvider),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Above the router rather than inside a shell, so a new order announces
      // itself on whatever screen the tenant happens to be on.
      builder: (context, child) =>
          NewOrderBannerOverlay(child: child ?? const SizedBox.shrink()),
    );
  }
}

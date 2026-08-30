import 'package:dtw_app/core/notifications/new_order_alert.dart';
import 'package:dtw_app/core/notifications/new_order_alert_controller.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obra_icons/obra_icons.dart';

/// Overlays the in-app "Orderan Baru Masuk" banner above [child].
///
/// Wraps the whole app rather than the tenant order screen: an order can land
/// while the tenant is editing a menu or reading Laporan, and a banner that
/// only appears on one tab would miss exactly the cases it exists for. Only
/// the tenant socket feeds it, so a busboy session never sees one.
class NewOrderBannerOverlay extends ConsumerWidget {
  const NewOrderBannerOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alert = ref.watch(newOrderAlertBannerProvider);
    return Stack(
      children: [
        child,
        // With no alert the switcher's child is a zero-size box, so this
        // layer has nothing to hit-test and taps reach `child` normally —
        // that is what keeps a permanently-mounted overlay from eating the
        // top of every screen. `new_order_banner_test.dart` holds it.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => SlideTransition(
              position: Tween(
                begin: const Offset(0, -1),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: alert == null
                ? const SizedBox.shrink()
                : NewOrderBanner(
                    key: ValueKey(alert.orderId),
                    alert: alert,
                    onDismiss: () => ref
                        .read(newOrderAlertBannerProvider.notifier)
                        .dismiss(),
                    // Navigates through the router *instance*, not
                    // `context.goNamed`. This overlay is mounted from
                    // `MaterialApp.builder`, whose context sits ABOVE the
                    // Router — so an inherited lookup finds nothing and
                    // "Lihat" throws "No GoRouter found in context".
                    onOpen: () {
                      ref.read(newOrderAlertBannerProvider.notifier).dismiss();
                      ref.read(appRouterProvider).goNamed(TenantRoutes.order);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

/// The banner itself: a green card that drops in under the status bar.
class NewOrderBanner extends StatelessWidget {
  const NewOrderBanner({
    required this.alert,
    required this.onDismiss,
    required this.onOpen,
    super.key,
  });

  final NewOrderAlert alert;
  final VoidCallback onDismiss;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Dismissible(
        key: const ValueKey('new-order-banner'),
        direction: DismissDirection.up,
        onDismissed: (_) => onDismiss(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Material(
            color: AppColors.successGreen,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      ObraIcons.notification,
                      size: 22,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            alert.title,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            alert.body,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Lihat',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:obra_icons/obra_icons.dart';

/// The green header band at the top of the tenant Order home
/// (`menu-order-baru`): a white iOS status bar, the tenant name (`KFC Fried
/// Chicken`) with a notification bell. The white tab/list panel drawn by the
/// screen sits directly below this band.
class TenantOrderHeader extends StatelessWidget {
  const TenantOrderHeader({
    required this.tenantName,
    this.onBellTap,
    super.key,
  });

  /// Tenant display name, rendered bold-white (wraps to two lines in the
  /// reference, e.g. `KFC\nFried Chicken`).
  final String tenantName;

  /// Notification bell handler. Optional.
  final VoidCallback? onBellTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      // TODO(open-question): the header on the tenant order frames is a
      // photographic deep-green raster ("ChatGPT Image ..." 538x359) that was
      // not exported to the asset cache; these two stops approximate it
      // (shared with the busboy Performa/Order headers). Swap for the real
      // asset once available.
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.headerGreenTop, AppColors.headerGreenBottom],
        ),
      ),
      child: Column(
        children: [
          // The OS draws the real status bar here; the header runs behind
          // it. A fake `9:41` bar used to sit in this slot, doubling up with
          // the real one on device.
          SizedBox(height: MediaQuery.paddingOf(context).top),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    tenantName,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _BellButton(onTap: onBellTap),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The notification bell button (`Frame 2012`): a translucent 36x36 circle
/// with a white bell glyph.
class _BellButton extends StatelessWidget {
  const _BellButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            // White @ ~18% — translucent circle over the green header.
            color: Color(0x2EFFFFFF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            ObraIcons.notification,
            size: 20,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

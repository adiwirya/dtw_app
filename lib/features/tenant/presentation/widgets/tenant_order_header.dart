import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:obra_icons/obra_icons.dart';

/// The green header band at the top of the tenant Order home
/// (`menu-order-baru`): a white iOS status bar, the tenant name (`KFC Fried
/// Chicken`) with a notification bell, and an "Online" status pill. The white
/// tab/list panel drawn by the screen sits directly below this band.
class TenantOrderHeader extends StatelessWidget {
  const TenantOrderHeader({
    required this.tenantName,
    this.isOnline = true,
    this.onBellTap,
    super.key,
  });

  /// Tenant display name, rendered bold-white (wraps to two lines in the
  /// reference, e.g. `KFC\nFried Chicken`).
  final String tenantName;

  /// Drives the "Online" pill dot/label.
  final bool isOnline;

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
          const _WhiteStatusBar(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tenantName,
                        // TODO(open-question): Open Sans Bold in the cache; not
                        // bundled yet (mirrors the other tenant headers).
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _OnlinePill(online: isOnline),
                    ],
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

/// The "Online" status pill (`Frame 2011`): a dot + label on a translucent
/// rounded chip.
class _OnlinePill extends StatelessWidget {
  const _OnlinePill({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        // White @ ~18% — translucent chip over the green header.
        color: const Color(0x2EFFFFFF),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: online ? AppColors.white : AppColors.neutral300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            online ? 'Online' : 'Offline',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1,
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

/// White-on-green status bar (`9:41` + signal / wifi / battery). Mirrors the
/// busboy Order/Performa headers.
// TODO(open-question): pixel-exact SVG glyphs are approximated with Material
// icons until flutter_svg is available.
class _WhiteStatusBar extends StatelessWidget {
  const _WhiteStatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 44,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '9:41',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
            Row(
              children: [
                Icon(Icons.signal_cellular_alt, size: 17, color: Colors.white),
                SizedBox(width: 6),
                Icon(Icons.wifi, size: 17, color: Colors.white),
                SizedBox(width: 6),
                Icon(Icons.battery_full, size: 22, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

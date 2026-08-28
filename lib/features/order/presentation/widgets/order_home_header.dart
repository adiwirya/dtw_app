import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/order/data/models/order_models.dart';
import 'package:flutter/material.dart';

/// The green header band at the top of the Order home (`menu-order-baru`):
/// a white iOS status bar, an avatar + greeting row, and a floating white
/// summary-stats card. The white tab/list panel drawn by the screen sits
/// directly below this band.
class OrderHomeHeader extends StatelessWidget {
  const OrderHomeHeader({required this.stats, this.username, super.key});

  /// The three summary stats rendered in the floating card.
  final List<OrderHeaderStat> stats;

  /// The logged-in user's username (`sessionUsernameProvider`). A login handle
  /// rather than a display name — the API has no display-name field — so it is
  /// shown as-is. Null (unknown) drops the name from the greeting instead of
  /// substituting a placeholder one.
  final String? username;

  @override
  Widget build(BuildContext context) {
    return Container(
      // TODO(open-question): the header on the menu-order frames is a
      // photographic green gradient raster ("ChatGPT Image ..." 390x341) that
      // was not exported to the asset cache; these two stops approximate it
      // (shared with Performa/Akun). Swap for the real asset once available.
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _GreetingRow(username: username),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _StatsCard(stats: stats),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow({this.username});

  final String? username;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // TODO(open-question): the avatar raster ("ChatGPT Image ..." 40x40)
        // was not exported to the asset cache; using a tinted placeholder.
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.successTint,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            size: 24,
            color: AppColors.success700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                username == null ? 'Hi 👋' : 'Hi, $username 👋',
                // TODO(open-question): Open Sans Bold in cache; not bundled.
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Siap melayani pesanan hari ini',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The floating white 3-up stats card (`Rectangle 370` + `Frame 2442` ×3).
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final List<OrderHeaderStat> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          for (final stat in stats)
            Expanded(child: _StatColumn(stat: stat)),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.stat});

  final OrderHeaderStat stat;

  @override
  Widget build(BuildContext context) {
    final valueColor = Color(stat.color);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              stat.value,
              // TODO(open-question): Open Sans Bold in the cache; not bundled.
              style: TextStyle(
                color: valueColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            if (stat.showStar) ...[
              const SizedBox(width: 3),
              const Icon(Icons.star, size: 16, color: AppColors.starAmber),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          stat.label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.neutral500,
            fontSize: 12,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

/// White-on-green status bar (`9:41` + signal / wifi / battery). Mirrors the
/// Performa/Akun headers.
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

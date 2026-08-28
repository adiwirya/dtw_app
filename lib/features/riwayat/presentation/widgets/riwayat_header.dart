import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:obra_icons/obra_icons.dart';

/// The green gradient band at the top of the `riwayat-*` frames: a white iOS
/// status bar over a nav row with a centered `Riwayat` title and a trailing
/// funnel (filter) action. The white search/list panel drawn by the screen
/// overlaps the bottom of this band.
class RiwayatHeader extends StatelessWidget {
  const RiwayatHeader({this.onFilterTap, super.key});

  /// Tap handler for the trailing funnel/filter action.
  // TODO(open-question): the filter action's behavior (filter sheet vs. sort)
  // is unspecified in the references; wired but no-op by default.
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      // TODO(open-question): the header on the riwayat frames is a photographic
      // green gradient raster ("ChatGPT Image ..." 390x341) that was not
      // exported to the asset cache; these two stops approximate it (shared
      // with Order/Performa/Akun). Swap for the real asset once available.
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
          SizedBox(
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Center(
                  child: Padding(
                    // Nudge above the overlapping panel so the title sits
                    // centered in the exposed green nav row.
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Riwayat',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 4,
                  child: IconButton(
                    onPressed: onFilterTap,
                    iconSize: 24,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    icon: const Icon(
                      ObraIcons.filter,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// White-on-green status bar (`9:41` + signal / wifi / battery). Mirrors the
/// Order / Performa / Akun headers.
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

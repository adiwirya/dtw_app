import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The green gradient band at the top of the `akun` frame: a white iOS status
/// bar over a centered `Akun` title. The white content panel drawn by the
/// screen overlaps the bottom of this band.
class AkunHeader extends StatelessWidget {
  const AkunHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      // TODO(open-question): the header on the akun frame is a photographic
      // green gradient raster ("ChatGPT Image ..." 390x341) that was not
      // exported to the asset cache; these two stops approximate it (same as
      // the Performa header). Swap for the real asset once available.
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.headerGreenTop, AppColors.headerGreenBottom],
        ),
      ),
      child: const Column(
        children: [
          _WhiteStatusBar(),
          Expanded(
            child: Center(
              child: Padding(
                // Nudge above the overlapping card so the title sits centered
                // in the exposed green band.
                padding: EdgeInsets.only(bottom: 34),
                child: Text(
                  'Akun',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White-on-green status bar (`9:41` + signal / wifi / battery).
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

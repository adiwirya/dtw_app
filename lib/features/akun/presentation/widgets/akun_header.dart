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
      child: Column(
        children: [
          // The OS draws the real status bar here; the header runs behind
          // it. A fake `9:41` bar used to sit in this slot, doubling up with
          // the real one on device.
          SizedBox(height: MediaQuery.paddingOf(context).top),
          const Expanded(
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

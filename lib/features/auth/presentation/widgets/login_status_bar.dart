import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The iOS-style status bar drawn at the top of the login frames (`9:41` plus
/// signal / wifi / battery glyphs). It reproduces the design chrome so the
/// screen matches the cached reference; on a real device the OS status bar
/// would sit here instead.
// TODO(open-question): pixel-exact SVG glyphs (Cellular / Wifi / Battery) are
// approximated with Material icons until flutter_svg is available.
class LoginStatusBar extends StatelessWidget {
  const LoginStatusBar({super.key});

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
                color: AppColors.neutral900,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.signal_cellular_alt,
                  size: 17,
                  color: AppColors.neutral900,
                ),
                SizedBox(width: 6),
                Icon(Icons.wifi, size: 17, color: AppColors.neutral900),
                SizedBox(width: 6),
                Icon(
                  Icons.battery_full,
                  size: 22,
                  color: AppColors.neutral900,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

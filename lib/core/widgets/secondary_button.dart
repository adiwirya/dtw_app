import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Full-width outlined pill, the quieter sibling of `PrimaryButton` (e.g. the
/// login screen's "Masuk dengan Tap Kartu"): white fill, success-green border
/// and label, height 40, radius 100.
///
/// A null [onPressed] renders the disabled state and swallows taps.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    this.onPressed,
    this.color = AppColors.successGreen,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Border and label color — success green by default, e.g. `dangerRed` for
  /// a destructive action like "Tolak".
  final Color color;

  @override
  Widget build(BuildContext context) {
    final color = onPressed == null
        ? this.color.withValues(alpha: 0.4)
        : this.color;
    final radius = BorderRadius.circular(100);

    return SizedBox(
      height: 40,
      width: double.infinity,
      child: Material(
        color: AppColors.white,
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: color),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

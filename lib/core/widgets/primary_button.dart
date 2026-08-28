import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Full-width success-green pill button used for primary actions (e.g. the
/// login screen's "Masuk").
///
/// Passing a null [onPressed] renders the disabled state and swallows taps.
///
/// Cached design values (`login-default`): height 40, corner radius 100,
/// background `#10A760`, label Open Sans SemiBold 16 white.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    this.onPressed,
    super.key,
  });

  /// Text rendered in the center of the button.
  final String label;

  /// Tap handler. When null the button is disabled and ignores taps.
  final VoidCallback? onPressed;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    // TODO(open-question): exact disabled color isn't in the cache; using a
    // dimmed success green until the design system defines a disabled token.
    final color = _enabled
        ? AppColors.successGreen
        : AppColors.successGreen.withValues(alpha: 0.4);
    final radius = BorderRadius.circular(100);

    return SizedBox(
      height: 40,
      width: double.infinity,
      child: Material(
        color: color,
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                // SemiBold
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

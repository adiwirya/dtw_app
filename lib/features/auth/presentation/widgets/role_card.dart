import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The two login flavors offered on the `login-default` / `login-tenantt`
/// frames.
enum LoginRole { tenan, busboy }

/// A "Masuk Sebagai" role card (`Component 26` in the cache).
///
/// Unselected: white surface with the card drop-shadow. Selected: a light
/// success tint fill, a success-green border, and a check badge in the
/// top-right corner (`login-tenantt` Busboy card).
class RoleCard extends StatelessWidget {
  const RoleCard({
    required this.title,
    required this.description,
    required this.assetPath,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// Role name shown in bold (e.g. "Tenan" / "Busboy").
  final String title;

  /// Two-line supporting copy under the title.
  final String description;

  /// Resolution-aware role illustration bundled under `assets/images/`.
  final String assetPath;

  /// Whether this card is the active selection.
  final bool selected;

  /// Invoked when the card is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 169,
        decoration: BoxDecoration(
          color: selected ? AppColors.cardSelectedFill : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: AppColors.cardSelectedBorder, width: 1.5)
              : null,
          boxShadow: const [
            // Card Shadow — #063336 @ 10%, offset (0,2), blur 16.
            BoxShadow(
              color: Color(0x1A063336),
              blurRadius: 16,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: AppColors.successTint,
                      shape: BoxShape.circle,
                    ),
                    // The exported illustration carries its own transparent
                    // padding, so rendering it at 60px yields the ~30px figure
                    // seen in the reference.
                    child: Image.asset(assetPath, width: 60, height: 60),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    // TODO(open-question): Open Sans Bold in the cache; not
                    // bundled yet, so this uses the default family.
                    style: const TextStyle(
                      color: AppColors.neutral900,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.neutral500,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.successGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: AppColors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

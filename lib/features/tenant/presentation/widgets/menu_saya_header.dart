import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The Menu Saya list header (`menu-saya` Frame 2133): a bold title with a
/// tenant name + booth subtitle on the left and a green icon+label action on
/// the right.
///
/// The trailing action swaps between "Kelola Menu" (the default list) and
/// "+ Tambah Menu" (the `menu-berhasil-ditambahkan` frame) via [actionLabel] /
/// [actionIcon].
class MenuSayaHeader extends StatelessWidget {
  const MenuSayaHeader({
    required this.actionLabel,
    required this.actionIcon,
    this.onAction,
    this.title = 'Menu Saya',
    this.subtitleName = 'KFC Friend Chicken',
    this.subtitleBooth = 'Both A12',
    super.key,
  });

  /// Trailing action caption, e.g. `Kelola Menu`.
  final String actionLabel;

  /// Trailing action glyph (sliders for Kelola Menu, plus for Tambah Menu).
  final IconData actionIcon;

  /// Trailing action tap handler.
  final VoidCallback? onAction;

  /// Bold heading.
  final String title;

  /// First subtitle segment (tenant name).
  final String subtitleName;

  /// Second subtitle segment (booth), shown after a dot separator.
  final String subtitleBooth;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      subtitleName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.neutral500,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: AppColors.neutral300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      subtitleBooth,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.neutral500,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _Action(label: actionLabel, icon: actionIcon, onTap: onAction),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.successGreen),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.successGreen,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

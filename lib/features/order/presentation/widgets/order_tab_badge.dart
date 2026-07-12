import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The small coloured count pill shown after a Menu Order sub-tab label
/// (`Frame 2440` badge instance on `menu-order-baru`): a filled circle with a
/// white count. Used as the `badge` of a `SegmentedTabItem`.
class OrderTabBadge extends StatelessWidget {
  const OrderTabBadge({required this.count, required this.color, super.key});

  /// Number shown inside the pill.
  final int count;

  /// Fill colour (red for "Ambil", amber for "Antar").
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        // TODO(open-question): Open Sans in the cache; not bundled.
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

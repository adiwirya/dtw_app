import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A single tab in a [SegmentedTabBar].
///
/// Only [label] is required — [icon] and [badge] are optional so the same
/// bar serves both the Menu Order sub-tabs (icon + count badge: Ambil / Antar
/// / Selesai) and the Riwayat date tabs (label only: Hari Ini / Kemarin / 7
/// Hari Terakhir).
@immutable
class SegmentedTabItem {
  const SegmentedTabItem({
    required this.label,
    this.icon,
    this.badge,
  });

  /// Text shown in the segment.
  final String label;

  /// Optional leading glyph rendered before the label (e.g. an obra icon on
  /// the Menu Order tabs). The icon inherits the segment's active/inactive
  /// color.
  final IconData? icon;

  /// Optional trailing widget after the label — typically a count chip. Kept
  /// as an arbitrary [Widget] so the consumer owns the badge's own styling
  /// (the Order tabs use differently-colored count pills).
  final Widget? badge;
}

/// Reusable underline-style segmented tab bar, generic over N labeled segments.
///
/// Visual style is taken from the `menu-order-baru` and `riwayat-hari-ini`
/// design references: equal-width segments over a full-width neutral base
/// divider, the selected segment marked by success-green text plus a 2px
/// success-green underline; unselected segments use neutral-500 text and no
/// underline.
///
/// Consumers: item 07 (Menu Order: Baru / Antar / Selesai) and item 09
/// (Riwayat: Hari Ini / Kemarin / 7 Hari Terakhir).
class SegmentedTabBar extends StatelessWidget {
  const SegmentedTabBar({
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  /// The segments to render, left to right. Must be non-empty.
  final List<SegmentedTabItem> items;

  /// Index of the currently selected segment.
  final int selectedIndex;

  /// Called with the tapped segment's index. Not invoked when the already
  /// selected segment is tapped.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.neutral100),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _Segment(
                item: items[i],
                selected: i == selectedIndex,
                onTap: i == selectedIndex ? null : () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SegmentedTabItem item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.successGreen : AppColors.neutral500;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 43,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.icon != null) ...[
                      Icon(item.icon, size: 16, color: color),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        // TODO(open-question): family is Open Sans in the
                        // design cache; the app doesn't bundle it yet, so this
                        // uses the default family (matches PrimaryButton).
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          height: 1,
                        ),
                      ),
                    ),
                    if (item.badge != null) ...[
                      const SizedBox(width: 6),
                      item.badge!,
                    ],
                  ],
                ),
              ),
            ),
            // 2px success-green underline for the active segment; the shared
            // neutral base divider (on the parent) shows through otherwise.
            Container(
              height: 2,
              color: selected ? AppColors.successGreen : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

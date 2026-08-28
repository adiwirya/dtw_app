import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/riwayat/data/models/riwayat_models.dart';
import 'package:flutter/material.dart';
import 'package:obra_icons/obra_icons.dart';

/// A single completed-order row on the Riwayat home (`riwayat-*` frames).
///
/// Purpose-built rather than reusing `OrderCard`: the history row is a much
/// simpler card than the Menu Order card — no icon tiles, no "Dari Tenant"
/// row, no divider, no primary-action button. It is a white 12px-radius card
/// (`Card Shadow` drop shadow) laid out as (cached `Frame 2590`, 358x90, 12px
/// padding):
///   - a top meta row: `time` (left) / `statusLabel` (right)
///   - the tenant name (bold title)
///   - a footer row: `tableName • location` (left) / `Detail ›` (right)
///
/// The whole card and the explicit `Detail` affordance both invoke [onTap]
/// (open `detail-riwayat`).
class HistoryRow extends StatelessWidget {
  const HistoryRow({required this.entry, this.onTap, super.key});

  /// The completed order to render.
  final RiwayatEntry entry;

  /// Opens the history detail (`detail-riwayat`). Wired to the whole card and
  /// the `Detail ›` affordance.
  final VoidCallback? onTap;

  // --- Cached design tokens (riwayat-* frames) ----------------------------

  static const double _radius = 12;
  static const double _pad = 12;

  // Text styles. No family is set: `Text` merges these onto the ambient
  // `DefaultTextStyle`, which the theme sources from Open Sans.
  static const TextStyle _metaStyle = TextStyle(
    color: AppColors.neutral500,
    fontSize: 12,
    height: 1.2,
  );
  static const TextStyle _titleStyle = TextStyle(
    color: AppColors.neutral900,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const TextStyle _footerStyle = TextStyle(
    color: AppColors.neutral500,
    fontSize: 14,
    height: 1.2,
  );
  static const TextStyle _detailStyle = TextStyle(
    color: AppColors.successGreen,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow, // rgba(6,51,54,0.10)
            offset: Offset(0, 2),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(_pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _metaRow(),
                const SizedBox(height: 8),
                Text(entry.tenantName, style: _titleStyle),
                const SizedBox(height: 4),
                _footerRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(entry.time, style: _metaStyle),
        Text(entry.statusLabel, style: _metaStyle),
      ],
    );
  }

  Widget _footerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  entry.tableName,
                  style: _footerStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _dot(),
              Flexible(
                child: Text(
                  entry.location,
                  style: _footerStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onTap,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Detail', style: _detailStyle),
              SizedBox(width: 2),
              Icon(
                ObraIcons.chevron_right,
                size: 14,
                color: AppColors.successGreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// `<a> • <b>` with an 8px gap either side of the neutral dot.
  Widget _dot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 4,
        height: 4,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.neutral500,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

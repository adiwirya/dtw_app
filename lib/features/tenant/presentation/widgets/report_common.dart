import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/tenant/data/models/laporan_report.dart';
import 'package:flutter/material.dart';
import 'package:obra_icons/obra_icons.dart';

/// The "Title …………… Lihat Semua ›" heading row shared by every report card.
class LaporanSectionHeader extends StatelessWidget {
  const LaporanSectionHeader({
    required this.title,
    this.action = 'Lihat Semua',
    super.key,
  });

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            // TODO(open-question): Open Sans Bold in cache; not bundled.
            style: const TextStyle(
              color: AppColors.neutral900,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            color: AppColors.successGreen,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const SizedBox(width: 2),
        const Icon(
          ObraIcons.chevron_right,
          size: 16,
          color: AppColors.successGreen,
        ),
      ],
    );
  }
}

/// The pale-green "Rekomendasi / Tips / Insight" callout used inside several
/// report cards. Mirrors the busboy Performa `InsightCard` but is driven by a
/// [ReportCallout] so the tenant feature stays decoupled from the Performa
/// model.
class ReportCalloutCard extends StatelessWidget {
  const ReportCalloutCard({required this.callout, super.key});

  final ReportCallout callout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TODO(open-question): the `idea-svgrepo` bulb glyph is approximated
          // with an obra_icons lightbulb until flutter_svg is available.
          const Icon(
            ObraIcons.lightbulb,
            size: 20,
            color: AppColors.success700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  callout.title,
                  style: const TextStyle(
                    color: AppColors.success700,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  callout.body,
                  style: const TextStyle(
                    color: AppColors.success700,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The small green "↑ delta" trend pill (mirrors the busboy `DeltaPill`,
/// re-implemented locally so the delta text can be styled per placement).
class TrendPill extends StatelessWidget {
  const TrendPill({
    required this.text,
    this.background = AppColors.successTint,
    this.foreground = AppColors.successGreen,
    super.key,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ObraIcons.arrow_up, size: 12, color: foreground),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

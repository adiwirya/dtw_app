import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/tenant/data/models/laporan_report.dart';
import 'package:flutter/material.dart';
import 'package:obra_icons/obra_icons.dart';

/// The dark-green hero card ("Total Pendapatan Rp 2.450.000") at the top of the
/// report body.
class ReportSummaryCard extends StatelessWidget {
  const ReportSummaryCard({required this.summary, super.key});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.headerGreenTop, AppColors.headerGreenBottom],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.label,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.value,
                      // TODO(open-question): Open Sans Bold in cache.
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  ObraIcons.wallet,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(ObraIcons.arrow_up, size: 16, color: AppColors.white),
              const SizedBox(width: 2),
              Text(
                summary.delta,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  summary.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The 2x2 grid of summary metric tiles under the hero card.
class LaporanMetricGrid extends StatelessWidget {
  const LaporanMetricGrid({required this.metrics, super.key});

  final List<ReportMetric> metrics;

  @override
  Widget build(BuildContext context) {
    Widget row(ReportMetric a, ReportMetric b) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _MetricTile(metric: a)),
            const SizedBox(width: 12),
            Expanded(child: _MetricTile(metric: b)),
          ],
        );

    return Column(
      children: [
        for (var i = 0; i < metrics.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          IntrinsicHeight(child: row(metrics[i], metrics[i + 1])),
        ],
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final ReportMetric metric;

  @override
  Widget build(BuildContext context) {
    final accent = Color(metric.accent);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(ObraIcons.shopping_basket, size: 14, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.neutral500,
                    fontSize: 12,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.neutral900,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(ObraIcons.arrow_up,
                      size: 12, color: AppColors.successGreen),
                  const SizedBox(width: 1),
                  Text(
                    metric.delta,
                    style: const TextStyle(
                      color: AppColors.successGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

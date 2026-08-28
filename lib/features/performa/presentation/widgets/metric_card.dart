import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/performa/data/models/performa_dashboard.dart';
import 'package:flutter/material.dart';

/// The 2x2 "Ringkasan Performa" grid of [MetricCard]s. Two 175px cards per row
/// with an 8px gutter (2*175 + 8 = 358 = the 16px-inset content width).
class MetricGrid extends StatelessWidget {
  const MetricGrid({required this.metrics, super.key});

  final List<PerformaMetric> metrics;

  @override
  Widget build(BuildContext context) {
    Widget row(PerformaMetric a, PerformaMetric b) => Row(
          children: [
            Expanded(child: MetricCard(metric: a)),
            const SizedBox(width: 8),
            Expanded(child: MetricCard(metric: b)),
          ],
        );

    return Column(
      children: [
        for (var i = 0; i < metrics.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          row(metrics[i], metrics[i + 1]),
        ],
      ],
    );
  }
}

/// A single summary tile (`Rectangle 371/372/373`, 175x93).
class MetricCard extends StatelessWidget {
  const MetricCard({required this.metric, super.key});

  final PerformaMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 93,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ValueLine(spans: metric.value, showStar: metric.showStar),
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.neutral500,
              fontSize: 12,
              height: 1.1,
            ),
          ),
          DeltaPill(text: metric.delta),
        ],
      ),
    );
  }
}

class _ValueLine extends StatelessWidget {
  const _ValueLine({required this.spans, required this.showStar});

  final List<MetricSpan> spans;
  final bool showStar;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                for (final span in spans)
                  TextSpan(
                    text: span.text,
                    style: TextStyle(
                      color: AppColors.neutral900,
                      fontSize: span.emphasized ? 22 : 15,
                      fontWeight:
                          span.emphasized ? FontWeight.w700 : FontWeight.w400,
                      height: 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showStar) ...[
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 16, color: AppColors.starAmber),
        ],
      ],
    );
  }
}

/// The pale-green trend pill under a metric value (`↑ <delta>`).
class DeltaPill extends StatelessWidget {
  const DeltaPill({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.successTint,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TODO(open-question): `arrow-up-line` SVG approximated with a
          // Material icon until flutter_svg is available.
          const Icon(
            Icons.arrow_upward,
            size: 12,
            color: AppColors.successGreen,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.successGreen,
                fontSize: 11,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

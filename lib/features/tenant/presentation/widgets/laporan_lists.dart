import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/tenant/data/models/laporan_report.dart';
import 'package:flutter/material.dart';
import 'package:obra_icons/obra_icons.dart';

/// Rounded neutral placeholder for a food thumbnail.
// TODO(open-question): the per-item food photos were not exported to the 1x
// asset cache; a neutral placeholder stands in until they are bundled.
class _Thumb extends StatelessWidget {
  const _Thumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.neutralTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        ObraIcons.shopping_basket,
        size: 24,
        color: AppColors.neutral300,
      ),
    );
  }
}

/// "Menu Terlaris" (top-selling) list — ranked rows with a thumbnail, name,
/// sold count, and trailing revenue.
class TopItemsList extends StatelessWidget {
  const TopItemsList({required this.items, super.key});

  final List<TopItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            const Divider(height: 24, thickness: 1, color: AppColors.hairline),
          _TopItemRow(item: items[i]),
        ],
      ],
    );
  }
}

class _TopItemRow extends StatelessWidget {
  const _TopItemRow({required this.item});

  final TopItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            const _Thumb(),
            Positioned(
              left: -4,
              top: -4,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.successGreen,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${item.rank}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.soldLabel,
                style: const TextStyle(
                  color: AppColors.neutral500,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          item.price,
          style: const TextStyle(
            color: AppColors.neutral900,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

/// "Stok Menipis" (low-stock) list — thumbnail, name, remaining, and a status
/// badge pill.
class LowStockList extends StatelessWidget {
  const LowStockList({required this.items, super.key});

  final List<StockItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            const Divider(height: 24, thickness: 1, color: AppColors.hairline),
          _StockItemRow(item: items[i]),
        ],
      ],
    );
  }
}

class _StockItemRow extends StatelessWidget {
  const _StockItemRow({required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    final accent = Color(item.badgeAccent);
    return Row(
      children: [
        const _Thumb(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.remaining,
                style: const TextStyle(
                  color: AppColors.neutral500,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            item.badge,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Jam Ramai" (Rata-rata Order) — horizontal progress bars per time window.
class PeakHoursList extends StatelessWidget {
  const PeakHoursList({required this.bars, super.key});

  final List<PeakHourBar> bars;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < bars.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _PeakRow(bar: bars[i]),
        ],
      ],
    );
  }
}

class _PeakRow extends StatelessWidget {
  const _PeakRow({required this.bar});

  final PeakHourBar bar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            bar.time,
            style: const TextStyle(
              color: AppColors.neutral900,
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 5,
              color: AppColors.neutralTint,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: bar.fraction.clamp(0.0, 1.0),
                child: Container(color: AppColors.successGreen),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 52,
          child: Text(
            bar.orders,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.neutral500,
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Insight Otomatis" — a list of idea rows with a tinted bulb chip.
class AutoInsightsList extends StatelessWidget {
  const AutoInsightsList({required this.insights, super.key});

  final List<AutoInsight> insights;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < insights.length; i++) ...[
          if (i > 0)
            const Divider(height: 24, thickness: 1, color: AppColors.hairline),
          _AutoInsightRow(insight: insights[i]),
        ],
      ],
    );
  }
}

class _AutoInsightRow extends StatelessWidget {
  const _AutoInsightRow({required this.insight});

  final AutoInsight insight;

  @override
  Widget build(BuildContext context) {
    final accent = Color(insight.accent);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(ObraIcons.lightbulb, size: 18, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              insight.text,
              style: const TextStyle(
                color: AppColors.neutral900,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

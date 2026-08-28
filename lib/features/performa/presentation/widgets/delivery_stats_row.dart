import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/performa/data/models/performa_dashboard.dart';
import 'package:flutter/material.dart';

/// The three coloured delivery-time stats under "Waktu Antar" on `performa-v1`
/// (Rata-rata / Tercepat / Terlama).
class DeliveryStatsRow extends StatelessWidget {
  const DeliveryStatsRow({required this.stats, super.key});

  final List<DeliveryStat> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final stat in stats) Expanded(child: _StatColumn(stat: stat)),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.stat});

  final DeliveryStat stat;

  @override
  Widget build(BuildContext context) {
    final color = Color(stat.color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: stat.value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              TextSpan(
                text: ' ${stat.unit}',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stat.label,
          style: const TextStyle(
            color: AppColors.neutral500,
            fontSize: 12,
            height: 1,
          ),
        ),
      ],
    );
  }
}

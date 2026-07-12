import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/performa/data/models/performa_dashboard.dart';
import 'package:flutter/material.dart';

/// The `performa-v2` "Aktivitas Mingguan" chart: a left 0/10/20/30/40 axis and
/// seven day columns, each a value label above a single blue bar above its day
/// label. The "Hari Ini" column is highlighted in a darker blue.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({required this.bars, super.key});

  final List<WeeklyBar> bars;

  static const double _plotHeight = 127;
  static const double _maxY = 40;
  static const _axisLabels = ['40', '30', '20', '10', '0'];

  // Space between the bar baseline and the row bottom (day-label gap + label).
  static const double _baselineInset = 26;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Y axis: label content sits over the plot area, lifted above the day
        // labels so `0` lines up with the bars' baseline.
        Padding(
          padding: const EdgeInsets.only(bottom: _baselineInset),
          child: SizedBox(
            height: _plotHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final label in _axisLabels)
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.neutral500,
                      fontSize: 11,
                      height: 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final bar in bars) Expanded(child: _DayColumn(bar: bar)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({required this.bar});

  final WeeklyBar bar;

  @override
  Widget build(BuildContext context) {
    final height =
        (bar.value / WeeklyBarChart._maxY) * WeeklyBarChart._plotHeight;
    final barColor =
        bar.active ? AppColors.chartBarBlueActive : AppColors.chartBarBlueIdle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${bar.value}',
          style: TextStyle(
            color: bar.active ? AppColors.neutral900 : AppColors.neutral500,
            fontSize: 11,
            fontWeight: bar.active ? FontWeight.w700 : FontWeight.w400,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 16,
          height: height.clamp(2, WeeklyBarChart._plotHeight),
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          bar.label,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: TextStyle(
            color: bar.active ? AppColors.neutral900 : AppColors.neutral500,
            fontSize: 11,
            fontWeight: bar.active ? FontWeight.w600 : FontWeight.w400,
            height: 1,
          ),
        ),
      ],
    );
  }
}

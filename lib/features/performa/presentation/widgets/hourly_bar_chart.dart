import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/performa/data/models/performa_dashboard.dart';
import 'package:flutter/material.dart';

/// The `performa-v1` "Performa per Jam" grouped bar chart: a left 0/4/8/12
/// axis, seven hourly groups of three periwinkle bars, and a legend row.
class HourlyBarChart extends StatelessWidget {
  const HourlyBarChart({required this.groups, super.key});

  final List<HourlyGroup> groups;

  static const double _plotHeight = 118;
  static const double _maxY = 12;
  static const _axisLabels = ['12', '8', '4', '0'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Y axis labels, evenly distributed over the plot height.
            SizedBox(
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
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final group in groups)
                    Expanded(child: _Group(group: group)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _Legend(),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.group});

  final HourlyGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < group.values.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              _Bar(value: group.values[i]),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          group.time,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: const TextStyle(
            color: AppColors.neutral500,
            fontSize: 10,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final height = (value / HourlyBarChart._maxY) * HourlyBarChart._plotHeight;
    return Container(
      width: 8,
      height: height.clamp(2, HourlyBarChart._plotHeight),
      decoration: const BoxDecoration(
        color: AppColors.chartBarPeriwinkle,
        borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.chartBarPeriwinkle,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Pesanan diantarkan',
          style: TextStyle(
            color: AppColors.neutral500,
            fontSize: 12,
            height: 1,
          ),
        ),
      ],
    );
  }
}

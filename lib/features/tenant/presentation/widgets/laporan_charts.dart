import 'dart:math' as math;

import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/tenant/data/models/laporan_report.dart';
import 'package:flutter/material.dart';

/// A line chart used by both "Grafik Penjualan" and "Tren Penjualan": a left
/// y-axis, horizontal grid lines, a green poly-line through the series values,
/// optional dot markers, and an optional peak annotation bubble.
class LineChartView extends StatelessWidget {
  const LineChartView({required this.series, this.height = 150, super.key});

  final LineSeries series;
  final double height;

  static const double _yAxisWidth = 34;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: _yAxisWidth,
              height: height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final label in series.yLabels)
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.neutral300,
                        fontSize: 11,
                        height: 1,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SizedBox(
                height: height,
                child: CustomPaint(painter: _LineChartPainter(series)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: _yAxisWidth),
          child: Row(
            children: [
              for (final label in series.xLabels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.neutral300,
                      fontSize: 11,
                      height: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.series);

  final LineSeries series;

  @override
  void paint(Canvas canvas, Size size) {
    // Horizontal grid lines, one per y label.
    final grid = Paint()
      ..color = AppColors.hairline
      ..strokeWidth = 1;
    final rows = series.yLabels.length;
    for (var i = 0; i < rows; i++) {
      final y = size.height * i / (rows - 1);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (series.values.isEmpty) return;

    Offset pointAt(int i) {
      final n = series.values.length;
      final dx = n == 1 ? size.width / 2 : size.width * i / (n - 1);
      final dy = size.height * (1 - (series.values[i] / series.maxY));
      return Offset(dx, dy);
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < series.values.length; i++) {
      final p = pointAt(i);
      final prev = pointAt(i - 1);
      // Gentle catmull-rom-ish smoothing via mid-point control handles.
      final cx = (prev.dx + p.dx) / 2;
      path.cubicTo(cx, prev.dy, cx, p.dy, p.dx, p.dy);
    }

    final line = Paint()
      ..color = AppColors.successGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, line);

    if (series.showDots) {
      final dotFill = Paint()..color = AppColors.white;
      final dotEdge = Paint()
        ..color = AppColors.successGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (var i = 0; i < series.values.length; i++) {
        final p = pointAt(i);
        canvas
          ..drawCircle(p, 4, dotFill)
          ..drawCircle(p, 4, dotEdge);
      }
    }

    final peakIndex = series.peakIndex;
    if (peakIndex != null && peakIndex < series.values.length) {
      final p = pointAt(peakIndex);
      // Vertical guide.
      final guide = Paint()
        ..color = AppColors.successGreen.withValues(alpha: 0.4)
        ..strokeWidth = 1;
      canvas
        ..drawLine(Offset(p.dx, 0), Offset(p.dx, size.height), guide)
        ..drawCircle(p, 4, Paint()..color = AppColors.successGreen);

      final label = series.peakLabel;
      if (label != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        const padH = 8.0;
        const padV = 4.0;
        final bw = tp.width + padH * 2;
        final bh = tp.height + padV * 2;
        var bx = p.dx - bw / 2;
        bx = bx.clamp(0.0, size.width - bw);
        final by = (p.dy - bh - 8).clamp(0.0, size.height);
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, bw, bh),
          const Radius.circular(6),
        );
        canvas.drawRRect(rect, Paint()..color = AppColors.successGreen);
        tp.paint(canvas, Offset(bx + padH, by + padV));
      }
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) =>
      oldDelegate.series != series;
}

/// Single-bar-per-hour vertical chart for "Jam Ramai Hari Ini".
class HourlyOrdersChart extends StatelessWidget {
  const HourlyOrdersChart({
    required this.busy,
    this.plotHeight = 150,
    super.key,
  });

  final BusyHours busy;
  final double plotHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Y axis labels lifted above the hour labels (24px band).
        Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: SizedBox(
            height: plotHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final label in busy.yLabels)
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.neutral300,
                      fontSize: 11,
                      height: 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final bar in busy.bars)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: ((bar.value / busy.maxY) * plotHeight)
                            .clamp(2, plotHeight),
                        decoration: const BoxDecoration(
                          color: AppColors.successGreen,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bar.hour,
                        style: const TextStyle(
                          color: AppColors.neutral300,
                          fontSize: 10,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The "Performa Menu" donut plus its legend column.
class MenuPerformanceChart extends StatelessWidget {
  const MenuPerformanceChart({required this.performance, super.key});

  final MenuPerformance performance;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 148,
          height: 148,
          child: CustomPaint(
            painter: _DonutPainter(performance.slices),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    performance.centerLabel,
                    style: const TextStyle(
                      color: AppColors.neutral500,
                      fontSize: 12,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    performance.centerValue,
                    style: const TextStyle(
                      color: AppColors.neutral900,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final slice in performance.slices)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color(slice.color),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              slice.label,
                              style: const TextStyle(
                                color: AppColors.neutral900,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              slice.amount,
                              style: const TextStyle(
                                color: AppColors.neutral500,
                                fontSize: 11,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        slice.percentLabel,
                        style: const TextStyle(
                          color: AppColors.neutral900,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices);

  final List<MenuSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 22.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    var start = -math.pi / 2;
    const gap = 0.04;
    for (final slice in slices) {
      final sweep = slice.percent * 2 * math.pi;
      final paint = Paint()
        ..color = Color(slice.color)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawArc(rect, start + gap / 2, sweep - gap, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) => oldDelegate.slices != slices;
}

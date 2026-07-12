import 'package:flutter/foundation.dart';

/// One styled fragment of a metric card's headline value.
///
/// The two Performa frames typeset values inconsistently (e.g. `95%` renders
/// the `%` large, while `96%` renders it small; `2m 48d` mixes large digits
/// with small units), so each metric stores its value as a list of spans that
/// are either [emphasized] (large + bold) or not (smaller + regular).
@immutable
class MetricSpan {
  const MetricSpan(this.text, {this.emphasized = true});

  final String text;
  final bool emphasized;
}

/// A single summary tile in the "Ringkasan Performa" 2x2 grid.
@immutable
class PerformaMetric {
  const PerformaMetric({
    required this.value,
    required this.label,
    required this.delta,
    this.showStar = false,
  });

  /// Headline value, split into [MetricSpan]s.
  final List<MetricSpan> value;

  /// Supporting caption under the value (e.g. "Tepat Waktu").
  final String label;

  /// Trend copy shown in the green pill (e.g. "8,7% dari kemarin").
  final String delta;

  /// Whether an amber rating star sits after the value (rating tile).
  final bool showStar;
}

/// One hourly group in the `performa-v1` "Performa per Jam" chart. Each group
/// renders three periwinkle bars whose heights are given on the chart's 0..12
/// scale.
@immutable
class HourlyGroup {
  const HourlyGroup({required this.time, required this.values});

  final String time;
  final List<double> values;
}

/// One coloured stat in the `performa-v1` "Waktu Antar" row.
@immutable
class DeliveryStat {
  const DeliveryStat({
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  final String value;
  final String unit;
  final String label;
  final int color; // ARGB value; resolved against AppColors in the widget.
}

/// One day column in the `performa-v2` "Aktivitas Mingguan" chart.
@immutable
class WeeklyBar {
  const WeeklyBar({
    required this.label,
    required this.value,
    this.active = false,
  });

  final String label;
  final int value;
  final bool active;
}

/// The daily-target progress block on `performa-v2`.
@immutable
class DailyTarget {
  const DailyTarget({
    required this.current,
    required this.total,
    required this.unit,
    required this.caption,
  });

  final int current;
  final int total;
  final String unit;
  final String caption;

  double get progress => total == 0 ? 0 : current / total;
}

/// The green "Insight Hari ini" callout on `performa-v2`.
@immutable
class PerformaInsight {
  const PerformaInsight({required this.title, required this.body});

  final String title;
  final String body;
}

/// Greeting shown in the green header of both frames.
@immutable
class PerformaGreeting {
  const PerformaGreeting({required this.name, required this.subtitle});

  final String name;
  final String subtitle;
}

/// Aggregate model backing the `performa-v1` frame.
@immutable
class PerformaV1Data {
  const PerformaV1Data({
    required this.greeting,
    required this.metrics,
    required this.hourly,
    required this.deliveryStats,
  });

  final PerformaGreeting greeting;
  final List<PerformaMetric> metrics;
  final List<HourlyGroup> hourly;
  final List<DeliveryStat> deliveryStats;
}

/// Aggregate model backing the `performa-v2` frame.
@immutable
class PerformaV2Data {
  const PerformaV2Data({
    required this.greeting,
    required this.metrics,
    required this.target,
    required this.weekly,
    required this.insight,
  });

  final PerformaGreeting greeting;
  final List<PerformaMetric> metrics;
  final DailyTarget target;
  final List<WeeklyBar> weekly;
  final PerformaInsight insight;
}

import 'package:flutter/foundation.dart';

/// Immutable view model backing the tenant **Laporan** (report) dashboard
/// (`laporan` frame). Every field is populated from mock data in
/// `laporanReportProvider` until the real reporting source lands
/// (see the `// TODO(open-question)` there).

/// The dark-green hero card at the top of the report ("Total Pendapatan").
@immutable
class ReportSummary {
  const ReportSummary({
    required this.label,
    required this.value,
    required this.delta,
    required this.caption,
  });

  final String label; // "Total Pendapatan"
  final String value; // "Rp 2.450.000"
  final String delta; // "12,5 %"
  final String caption; // "dibandingkan kemarin"
}

/// One tile in the 2x2 summary grid under the hero card.
@immutable
class ReportMetric {
  const ReportMetric({
    required this.label,
    required this.value,
    required this.delta,
    required this.accent,
  });

  final String label; // "Total Pesanan"
  final String value; // "125"
  final String delta; // "8,7%"
  final int accent; // ARGB accent for the leading icon chip.
}

/// A point-series line chart (used by both "Grafik Penjualan" and
/// "Tren Penjualan"). [values] are on the same scale as [yLabels]'s numeric
/// meaning; the widget normalises against [maxY].
@immutable
class LineSeries {
  const LineSeries({
    required this.values,
    required this.xLabels,
    required this.yLabels,
    required this.maxY,
    this.peakIndex,
    this.peakLabel,
    this.showDots = false,
  });

  final List<double> values;
  final List<String> xLabels;
  final List<String> yLabels; // top-to-bottom
  final double maxY;
  final int? peakIndex; // index to annotate with [peakLabel]
  final String? peakLabel; // e.g. "Rp 790.000"
  final bool showDots; // dot marker at every point (Tren Penjualan)
}

/// "Grafik Penjualan" card: a line chart with a period dropdown label.
@immutable
class SalesChart {
  const SalesChart({required this.periodLabel, required this.series});

  final String periodLabel; // "Per Jam"
  final LineSeries series;
}

/// One vertical bar in the "Jam Ramai Hari Ini" hourly chart.
@immutable
class HourBar {
  const HourBar({required this.hour, required this.value});

  final String hour; // "10".."22"
  final double value; // 0..maxY (orders)
}

/// A small "12:00 - 13:00 / 52 Orders" pill above the hourly chart.
@immutable
class BusyPill {
  const BusyPill({required this.time, required this.orders});

  final String time;
  final String orders;
}

/// "Jam Ramai Hari Ini" card.
@immutable
class BusyHours {
  const BusyHours({
    required this.pills,
    required this.bars,
    required this.maxY,
    required this.yLabels,
    required this.recommendation,
  });

  final List<BusyPill> pills;
  final List<HourBar> bars;
  final double maxY;
  final List<String> yLabels; // top-to-bottom (60/45/30/15/0)
  final ReportCallout recommendation;
}

/// One row in the "Menu Terlaris" (top-selling) list.
@immutable
class TopItem {
  const TopItem({
    required this.rank,
    required this.name,
    required this.soldLabel,
    required this.price,
  });

  final int rank;
  final String name;
  final String soldLabel; // "58 Terjual"
  final String price; // "Rp1.160.000"
}

/// One row in the "Stok Menipis" (low-stock) list.
@immutable
class StockItem {
  const StockItem({
    required this.name,
    required this.remaining,
    required this.badge,
    required this.badgeAccent,
  });

  final String name;
  final String remaining; // "Sisa 3 porsi"
  final String badge; // "Hampir Habis" / "Stok Menipis"
  final int badgeAccent; // ARGB
}

/// One slice / legend entry in the "Performa Menu" donut.
@immutable
class MenuSlice {
  const MenuSlice({
    required this.label,
    required this.amount,
    required this.percentLabel,
    required this.percent,
    required this.color,
  });

  final String label; // "Paket Komplit"
  final String amount; // "Rp1.176.000"
  final String percentLabel; // "48%"
  final double percent; // 0..1
  final int color; // ARGB
}

/// "Performa Menu" donut card.
@immutable
class MenuPerformance {
  const MenuPerformance({
    required this.centerLabel,
    required this.centerValue,
    required this.slices,
    required this.insight,
  });

  final String centerLabel; // "Total"
  final String centerValue; // "2.450.000"
  final List<MenuSlice> slices;
  final ReportCallout insight;
}

/// One row in the "Jam Ramai" (peak-hours) horizontal bar list.
@immutable
class PeakHourBar {
  const PeakHourBar({
    required this.time,
    required this.fraction,
    required this.orders,
  });

  final String time; // "12:00 - 13:00"
  final double fraction; // 0..1 of the track
  final String orders; // "42 Order"
}

/// "Jam Ramai" (Rata-rata Order) card.
@immutable
class PeakHours {
  const PeakHours({required this.bars, required this.tip});

  final List<PeakHourBar> bars;
  final ReportCallout tip;
}

/// "Tren Penjualan" card.
@immutable
class SalesTrend {
  const SalesTrend({
    required this.periodLabel,
    required this.total,
    required this.delta,
    required this.caption,
    required this.series,
  });

  final String periodLabel; // "7 Hari Terakhir"
  final String total; // "Rp15.870.000"
  final String delta; // "9,3%"
  final String caption; // "Dibanding 7 hari lalu"
  final LineSeries series;
}

/// One row in the "Insight Otomatis" list.
@immutable
class AutoInsight {
  const AutoInsight({required this.text, required this.accent});

  final String text;
  final int accent; // ARGB tint for the leading idea chip
}

/// The pale-green "Rekomendasi / Tips / Insight" callout shared by several
/// cards (mirrors the busboy Performa `InsightCard`).
@immutable
class ReportCallout {
  const ReportCallout({required this.title, required this.body});

  final String title;
  final String body;
}

/// Aggregate model backing the whole `laporan` frame.
@immutable
class LaporanReport {
  const LaporanReport({
    required this.tenantName,
    required this.tableLabel,
    required this.dateLabel,
    required this.filters,
    required this.activeFilter,
    required this.summary,
    required this.metrics,
    required this.salesChart,
    required this.busyHours,
    required this.topItems,
    required this.lowStock,
    required this.menuPerformance,
    required this.peakHours,
    required this.salesTrend,
    required this.autoInsights,
  });

  final String tenantName; // "KFC Friend Chicken"
  final String tableLabel; // "Both A12"
  final String dateLabel; // "Selasa, 13 Mei 2026"
  final List<String> filters; // Semua / Hari / ...
  final int activeFilter;
  final ReportSummary summary;
  final List<ReportMetric> metrics;
  final SalesChart salesChart;
  final BusyHours busyHours;
  final List<TopItem> topItems;
  final List<StockItem> lowStock;
  final MenuPerformance menuPerformance;
  final PeakHours peakHours;
  final SalesTrend salesTrend;
  final List<AutoInsight> autoInsights;
}

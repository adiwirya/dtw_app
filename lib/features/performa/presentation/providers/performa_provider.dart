import 'package:dtw_app/features/performa/data/models/performa_dashboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'performa_provider.g.dart';

// TODO(open-question): the metrics data source is unresolved (Open Question 2).
// Both providers below return hard-coded, in-memory mock data harvested from
// the Figma references. When the real source lands, replace these synchronous
// providers with an async repository fetch (`Future<PerformaV1Data>` backed by
// dio, per knowledge/riverpod-patterns.md) and have the screens consume the
// resulting AsyncValue.

const _greeting = PerformaGreeting(
  name: 'Adi Wiryadi',
  subtitle: 'Siap melayani pesanan hari ini',
);

/// Mock backing data for the `performa-v1` frame.
@riverpod
PerformaV1Data performaV1Data(Ref ref) {
  return const PerformaV1Data(
    greeting: _greeting,
    metrics: [
      PerformaMetric(
        value: [MetricSpan('95%')],
        label: 'Performa',
        delta: '8,7% dari kemarin',
      ),
      PerformaMetric(
        value: [MetricSpan('4'), MetricSpan(' Menit', emphasized: false)],
        label: 'Rata-rata waktu antar',
        delta: '5m lebih cepat',
      ),
      PerformaMetric(
        value: [MetricSpan('96%')],
        label: 'Tepat Waktu',
        delta: '4% dari kemarin',
      ),
      PerformaMetric(
        value: [MetricSpan('4.9')],
        label: 'Rating Pelanggan',
        delta: '0.2% dari kemarin',
        showStar: true,
      ),
    ],
    // Heights are on the chart's 0..12 scale, derived from the exported bar
    // pixel heights so the mock chart matches the reference silhouette.
    hourly: [
      HourlyGroup(time: '08:00', values: [2.1, 1.1, 4.6]),
      HourlyGroup(time: '10:00', values: [0.9, 8.0, 3.2]),
      HourlyGroup(time: '12:00', values: [4.1, 5.9, 1.3]),
      HourlyGroup(time: '14:00', values: [4.7, 1.5, 3.3]),
      HourlyGroup(time: '16:00', values: [5.3, 3.3, 7.0]),
      HourlyGroup(time: '18:00', values: [1.4, 3.9, 5.4]),
      HourlyGroup(time: '20:00', values: [3.1, 1.9, 1.1]),
    ],
    deliveryStats: [
      DeliveryStat(
        value: '6',
        unit: 'Menit',
        label: 'Rata-rata',
        color: 0xFF10A760, // AppColors.successGreen
      ),
      DeliveryStat(
        value: '4',
        unit: 'Menit',
        label: 'Tercepat',
        color: 0xFF3B82F6, // AppColors.accentBlue
      ),
      DeliveryStat(
        value: '8',
        unit: 'Menit',
        label: 'Terlama',
        color: 0xFFE9A23B, // AppColors.accentAmber
      ),
    ],
  );
}

/// Mock backing data for the `performa-v2` frame.
@riverpod
PerformaV2Data performaV2Data(Ref ref) {
  return const PerformaV2Data(
    greeting: _greeting,
    metrics: [
      PerformaMetric(
        value: [MetricSpan('32')],
        label: 'Pesanan Selesai',
        delta: '+8 dari kemarin',
      ),
      PerformaMetric(
        value: [
          MetricSpan('2'),
          MetricSpan('m ', emphasized: false),
          MetricSpan('48'),
          MetricSpan('d', emphasized: false),
        ],
        label: 'Rata-rata Antar',
        delta: '-8 detik lebih cepat',
      ),
      PerformaMetric(
        value: [MetricSpan('96'), MetricSpan('%', emphasized: false)],
        label: 'Tepat Waktu (SLA)',
        delta: '4% dari kemarin',
      ),
      PerformaMetric(
        value: [MetricSpan('4.9')],
        label: 'Rating Pelanggan',
        delta: '0.2% dari kemarin',
        showStar: true,
      ),
    ],
    target: DailyTarget(
      current: 28,
      total: 50,
      unit: 'Pesanan',
      caption: '22 Pesanan lagi untuk mencapai target harian 🎯',
    ),
    weekly: [
      WeeklyBar(label: 'Sen', value: 25),
      WeeklyBar(label: 'Sel', value: 28),
      WeeklyBar(label: 'Rab', value: 31),
      WeeklyBar(label: 'Kam', value: 22),
      WeeklyBar(label: 'Jum', value: 35),
      WeeklyBar(label: 'Sab', value: 15),
      WeeklyBar(label: 'Hari Ini', value: 28, active: true),
    ],
    insight: PerformaInsight(
      title: 'Insight Hari ini',
      body: 'Kamu menyelesaikan 5 pesanan lebih banyak dibanding kemarin. '
          'Pertahankan! 💪',
    ),
  );
}

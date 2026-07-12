import 'package:dtw_app/features/tenant/data/models/laporan_report.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'laporan_provider.g.dart';

// TODO(open-question): the report data source is unresolved (Open Question 5;
// the @1x reference was also unavailable — Open Question 7). Everything below
// is hard-coded, in-memory mock data harvested from the `laporan` Figma cache
// (tree.txt + values.json + the @0.5x reference). When the real reporting API
// lands, replace this synchronous provider with an async repository fetch
// (`Future<LaporanReport>` backed by dio, per knowledge/riverpod-patterns.md)
// and have the screen consume the resulting AsyncValue.

/// Mock backing data for the tenant `laporan` (report dashboard) frame.
@riverpod
LaporanReport laporanReport(Ref ref) {
  return const LaporanReport(
    tenantName: 'KFC Friend Chicken',
    tableLabel: 'Both A12',
    dateLabel: 'Selasa, 13 Mei 2026',
    filters: ['Semua', 'Hari', 'Minggu', 'Bulan', 'Tahun', 'Custom'],
    activeFilter: 1, // "Hari"
    summary: ReportSummary(
      label: 'Total Pendapatan',
      value: 'Rp 2.450.000',
      delta: '12,5 %',
      caption: 'dibandingkan kemarin',
    ),
    metrics: [
      ReportMetric(
        label: 'Total Pesanan',
        value: '125',
        delta: '8,7%',
        accent: 0xFF10A760, // successGreen
      ),
      ReportMetric(
        label: 'Rata-rata Order',
        value: 'Rp19.600',
        delta: '3,2%',
        accent: 0xFFE9A23B, // accentAmber
      ),
      ReportMetric(
        label: 'Pesanan Selesai',
        value: '188',
        delta: '9,4%',
        accent: 0xFF3B82F6, // accentBlue
      ),
      ReportMetric(
        label: 'Item Terjual',
        value: '96',
        delta: '8,7%',
        accent: 0xFF9B51E0, // orderTileCustomerIcon (purple)
      ),
    ],
    salesChart: SalesChart(
      periodLabel: 'Per Jam',
      series: LineSeries(
        // Silhouette lifted from the reference line (Rp, on a 0..1jt scale).
        values: [520, 500, 560, 640, 640, 790, 690, 620, 560, 580, 540, 560],
        xLabels: ['10', '', '12', '', '14', '', '16', '', '18', '', '20', '22'],
        yLabels: ['1 jt', '750', '500', '250'],
        maxY: 1000,
        peakIndex: 5,
        peakLabel: 'Rp 790.000',
      ),
    ),
    busyHours: BusyHours(
      pills: [
        BusyPill(time: '12:00 - 13:00', orders: '52 Orders'),
        BusyPill(time: '19:00 - 20:00', orders: '48 Orders'),
      ],
      // 13 hourly bars (10..22), values derived from the exported bar heights.
      bars: [
        HourBar(hour: '10', value: 20),
        HourBar(hour: '11', value: 32),
        HourBar(hour: '12', value: 52),
        HourBar(hour: '13', value: 44),
        HourBar(hour: '14', value: 32),
        HourBar(hour: '15', value: 20),
        HourBar(hour: '16', value: 12),
        HourBar(hour: '17', value: 20),
        HourBar(hour: '18', value: 32),
        HourBar(hour: '19', value: 44),
        HourBar(hour: '20', value: 50),
        HourBar(hour: '21', value: 32),
        HourBar(hour: '22', value: 20),
      ],
      maxY: 60,
      yLabels: ['60', '45', '30', '15', '0'],
      recommendation: ReportCallout(
        title: 'Rekomendasi',
        body: 'Siapkan stok lebih banyak pada pukul 11:00 dan 20:00 untuk '
            'melayani lonjakan pesanan',
      ),
    ),
    topItems: [
      TopItem(
        rank: 1,
        name: 'Paket Super Besar',
        soldLabel: '58 Terjual',
        price: 'Rp1.160.000',
      ),
      TopItem(
        rank: 2,
        name: 'Chicken Burger',
        soldLabel: '32 Terjual',
        price: 'Rp1.160.000',
      ),
      TopItem(
        rank: 3,
        name: 'Mocha Float',
        soldLabel: '21 Terjual',
        price: 'Rp1.160.000',
      ),
    ],
    lowStock: [
      StockItem(
        name: 'Paket Super Besar',
        remaining: 'Sisa 3 porsi',
        badge: 'Hampir Habis',
        badgeAccent: 0xFFE5484D, // dangerRed
      ),
      StockItem(
        name: 'Chicken Burger',
        remaining: 'Sisa 2 porsi',
        badge: 'Hampir Habis',
        badgeAccent: 0xFFE5484D,
      ),
      StockItem(
        name: 'Mocha Float',
        remaining: 'Sisa 5 Gelas',
        badge: 'Stok Menipis',
        badgeAccent: 0xFFE9A23B, // accentAmber
      ),
    ],
    menuPerformance: MenuPerformance(
      centerLabel: 'Total',
      centerValue: '2.450.000',
      slices: [
        MenuSlice(
          label: 'Paket Komplit',
          amount: 'Rp1.176.000',
          percentLabel: '48%',
          percent: 0.48,
          color: 0xFF10A760, // successGreen
        ),
        MenuSlice(
          label: 'Chicken Burg.',
          amount: 'Rp710.500',
          percentLabel: '29%',
          percent: 0.29,
          color: 0xFF3B82F6, // accentBlue
        ),
        MenuSlice(
          label: 'Cafe Mocha',
          amount: 'Rp392.000',
          percentLabel: '16%',
          percent: 0.16,
          color: 0xFFE9A23B, // accentAmber
        ),
        MenuSlice(
          label: 'Lainnya',
          amount: 'Rp172.000',
          percentLabel: '7%',
          percent: 0.07,
          color: 0xFF989FAD, // neutral300
        ),
      ],
      insight: ReportCallout(
        title: 'Insight',
        body: 'Paket komplit menyumbang 48% dari total pendapatan hari ini',
      ),
    ),
    peakHours: PeakHours(
      bars: [
        PeakHourBar(time: '12:00 - 13:00', fraction: 1, orders: '42 Order'),
        PeakHourBar(time: '19:00 - 20:00', fraction: 0.83, orders: '35 Order'),
        PeakHourBar(time: '13:00 - 14:00', fraction: 0.67, orders: '28 Order'),
        PeakHourBar(time: '18:00 - 19:00', fraction: 0.52, orders: '22 Order'),
        PeakHourBar(time: '15:00 - 16:00', fraction: 0.43, orders: '18 Order'),
      ],
      tip: ReportCallout(
        title: 'Tips',
        body: 'Jam 12:00 - 13:00 dan 19:00 - 20:00 adalah waktu tersibuk. '
            'Pastikan Stok dan persiapan Optimal!',
      ),
    ),
    salesTrend: SalesTrend(
      periodLabel: '7 Hari Terakhir',
      total: 'Rp15.870.000',
      delta: '9,3%',
      caption: 'Dibanding 7 hari lalu',
      series: LineSeries(
        values: [30, 33, 27, 24, 36, 42, 51],
        xLabels: [
          '13 Mei',
          '14 Mei',
          '15 Mei',
          '16 Mei',
          '17 Mei',
          '18 Mei',
          '19 Mei',
        ],
        yLabels: ['60', '45', '30', '15'],
        maxY: 60,
        showDots: true,
      ),
    ),
    autoInsights: [
      AutoInsight(
        text: 'Penjualan naik 12.5% dibanding kemarin Terus pertahankan '
            'performa bagus ini!',
        accent: 0xFF10A760, // successGreen
      ),
      AutoInsight(
        text: 'Chicken Burger sering habis pada jam 18:00 Pertimbangkan '
            'tambah stock di jam tersebut.',
        accent: 0xFFE9A23B, // accentAmber
      ),
      AutoInsight(
        text: 'Kamu memiliki 125 pelanggan baru minggu inni Bagus! '
            'Pertahankan kualitas pelayanan.',
        accent: 0xFF3B82F6, // accentBlue
      ),
    ],
  );
}

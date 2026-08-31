import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/performa/presentation/widgets/section_card.dart';
import 'package:dtw_app/features/tenant/data/models/laporan_report.dart';
import 'package:dtw_app/features/tenant/presentation/providers/laporan_provider.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/laporan_charts.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/laporan_header.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/laporan_lists.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/laporan_summary.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/report_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obra_icons/obra_icons.dart';

/// The `laporan` frame: the Laporan-tab report dashboard. A tall scrolling
/// report of sales/order metrics, charts, and breakdown sections. Hosted inside
/// `TenantShell`, so the bottom nav is provided by the shell.
class LaporanScreen extends ConsumerWidget {
  const LaporanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(laporanReportProvider);
    final branch = ref.watch(currentTenantBranchProvider).valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () {
            // `laporanReportProvider` is still mock (see the file), so this
            // just re-derives it; `currentTenantBranchProvider` is the one
            // real fetch the header depends on.
            ref.invalidate(laporanReportProvider);
            return ref.refresh(currentTenantBranchProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LaporanHeader(
                  // The report body below is still all mock data (see
                  // `laporan_provider.dart`), but tenant identity is real —
                  // same fix as the Order/Menu headers.
                  tenantName: branch?.branchName ?? report.tenantName,
                  tableLabel: branch?.areaName ?? report.tableLabel,
                  filters: report.filters,
                  activeFilter: report.activeFilter,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ReportSummaryCard(summary: report.summary),
                      const SizedBox(height: 16),
                      LaporanMetricGrid(metrics: report.metrics),
                      const SizedBox(height: 16),
                      _salesChartCard(report.salesChart),
                      const SizedBox(height: 16),
                      _busyHoursCard(report.busyHours),
                      const SizedBox(height: 16),
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const LaporanSectionHeader(title: 'Menu Terlaris'),
                            const SizedBox(height: 16),
                            TopItemsList(items: report.topItems),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const LaporanSectionHeader(title: 'Stok Menipis'),
                            const SizedBox(height: 16),
                            LowStockList(items: report.lowStock),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const LaporanSectionHeader(title: 'Performa Menu'),
                            const SizedBox(height: 16),
                            MenuPerformanceChart(
                              performance: report.menuPerformance,
                            ),
                            const SizedBox(height: 16),
                            ReportCalloutCard(
                              callout: report.menuPerformance.insight,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const LaporanSectionHeader(title: 'Jam Ramai'),
                            const SizedBox(height: 16),
                            PeakHoursList(bars: report.peakHours.bars),
                            const SizedBox(height: 16),
                            ReportCalloutCard(callout: report.peakHours.tip),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _salesTrendCard(report.salesTrend),
                      const SizedBox(height: 16),
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const LaporanSectionHeader(
                              title: 'Insight Otomatis',
                            ),
                            const SizedBox(height: 16),
                            AutoInsightsList(insights: report.autoInsights),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        report.dateLabel,
                        style: const TextStyle(
                          color: AppColors.neutral500,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _salesChartCard(SalesChart chart) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _headerWithDropdown('Grafik Penjualan', chart.periodLabel),
          const SizedBox(height: 16),
          LineChartView(series: chart.series),
        ],
      ),
    );
  }

  Widget _busyHoursCard(BusyHours busy) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LaporanSectionHeader(title: 'Jam Ramai Hari Ini'),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < busy.pills.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: _BusyPillBox(
                    pill: busy.pills[i],
                    accent: i == 0
                        ? AppColors.successGreen
                        : AppColors.accentAmber,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          HourlyOrdersChart(busy: busy),
          const SizedBox(height: 16),
          ReportCalloutCard(callout: busy.recommendation),
        ],
      ),
    );
  }

  Widget _salesTrendCard(SalesTrend trend) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _headerWithDropdown('Tren Penjualan', trend.periodLabel),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trend.total,
                      style: const TextStyle(
                        color: AppColors.neutral900,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Total pendapatan',
                      style: TextStyle(
                        color: AppColors.neutral500,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TrendPill(text: trend.delta),
                  const SizedBox(height: 4),
                  Text(
                    trend.caption,
                    style: const TextStyle(
                      color: AppColors.neutral500,
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          LineChartView(series: trend.series),
        ],
      ),
    );
  }

  Widget _headerWithDropdown(String title, String periodLabel) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.neutral900,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.neutralTint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                periodLabel,
                style: const TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                ObraIcons.chevron_down,
                size: 14,
                color: AppColors.neutral500,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BusyPillBox extends StatelessWidget {
  const _BusyPillBox({required this.pill, required this.accent});

  final BusyPill pill;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pill.time,
            style: const TextStyle(
              color: AppColors.neutral900,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            pill.orders,
            style: TextStyle(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

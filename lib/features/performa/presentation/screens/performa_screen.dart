import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/performa/presentation/providers/performa_provider.dart';
import 'package:dtw_app/features/performa/presentation/widgets/delivery_stats_row.dart';
import 'package:dtw_app/features/performa/presentation/widgets/hourly_bar_chart.dart';
import 'package:dtw_app/features/performa/presentation/widgets/metric_card.dart';
import 'package:dtw_app/features/performa/presentation/widgets/performa_header.dart';
import 'package:dtw_app/features/performa/presentation/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The `performa-v1` frame: the Performa-tab dashboard home. A green greeting
/// header over a white scrolling body of a summary grid, an hourly-performance
/// chart, and delivery-time stats. Hosted inside the app shell, so the bottom
/// nav is provided by `AppShell`.
class PerformaScreen extends ConsumerWidget {
  const PerformaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(performaV1DataProvider);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PerformaHeader(greeting: data.greeting),
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -16, 0),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  const Text(
                    'Ringkasan Performa',
                    // TODO(open-question): Open Sans Bold in the cache.
                    style: TextStyle(
                      color: AppColors.neutral900,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  MetricGrid(metrics: data.metrics),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Performa per Jam',
                    child: HourlyBarChart(groups: data.hourly),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Waktu Antar',
                    child: DeliveryStatsRow(stats: data.deliveryStats),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

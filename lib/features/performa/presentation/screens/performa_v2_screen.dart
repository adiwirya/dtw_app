import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/performa/presentation/providers/performa_provider.dart';
import 'package:dtw_app/features/performa/presentation/widgets/insight_card.dart';
import 'package:dtw_app/features/performa/presentation/widgets/metric_card.dart';
import 'package:dtw_app/features/performa/presentation/widgets/performa_header.dart';
import 'package:dtw_app/features/performa/presentation/widgets/section_card.dart';
import 'package:dtw_app/features/performa/presentation/widgets/target_progress.dart';
import 'package:dtw_app/features/performa/presentation/widgets/weekly_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The `performa-v2` frame: an alternate Performa dashboard layout. Same green
/// header + summary grid as v1, but swaps the hourly chart for a daily-target
/// block, a weekly-activity chart, and a green insight callout. Hosted inside
/// the app shell (bottom nav provided by `AppShell`).
class PerformaV2Screen extends ConsumerWidget {
  const PerformaV2Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(performaV2DataProvider);
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
                  SectionCard(child: TargetProgress(target: data.target)),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Aktivitas Mingguan',
                    child: WeeklyBarChart(bars: data.weekly),
                  ),
                  const SizedBox(height: 16),
                  InsightCard(insight: data.insight),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

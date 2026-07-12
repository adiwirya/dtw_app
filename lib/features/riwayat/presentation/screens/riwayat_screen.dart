import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/segmented_tab_bar.dart';
import 'package:dtw_app/features/riwayat/data/models/riwayat_models.dart';
import 'package:dtw_app/features/riwayat/presentation/providers/riwayat_provider.dart';
import 'package:dtw_app/features/riwayat/presentation/widgets/history_row.dart';
import 'package:dtw_app/features/riwayat/presentation/widgets/riwayat_header.dart';
import 'package:dtw_app/features/riwayat/presentation/widgets/riwayat_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The `riwayat-hari-ini` / `-kemarin` / `-7-hari` frames: the Riwayat (order
/// history) tab home.
///
/// One screen hosts all three date tabs (Hari Ini / Kemarin / 7 Hari
/// Terakhir); the shared [SegmentedTabBar] switches the date-grouped history
/// list in place (mirroring the Order home's sub-tab pattern via
/// [riwayatTabProvider]). Rows open `detail-riwayat`. Hosted inside the app
/// shell, so the bottom nav is provided by `AppShell`.
class RiwayatScreen extends ConsumerWidget {
  const RiwayatScreen({super.key});

  static const List<RiwayatRange> _ranges = [
    RiwayatRange.hariIni,
    RiwayatRange.kemarin,
    RiwayatRange.tujuhHari,
  ];

  void _openDetail(BuildContext context) {
    context.goNamed(AppRoutes.riwayatDetail);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(riwayatTabProvider);
    final range = _ranges[selected];
    final days = ref.watch(riwayatDaysProvider(range));

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RiwayatHeader(),
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -8, 0),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: RiwayatSearchField(),
                  ),
                  SegmentedTabBar(
                    selectedIndex: selected,
                    onChanged: (i) =>
                        ref.read(riwayatTabProvider.notifier).select(i),
                    items: const [
                      SegmentedTabItem(label: 'Hari Ini'),
                      SegmentedTabItem(label: 'Kemarin'),
                      SegmentedTabItem(label: '7 Hari Terakhir'),
                    ],
                  ),
                  Expanded(
                    child: _HistoryList(
                      days: days,
                      onDetail: () => _openDetail(context),
                    ),
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

/// The date-grouped history list: each [RiwayatDayGroup] renders a date header
/// (`<date>` / `<n> Tugas`) followed by its [HistoryRow]s. The `7 Hari
/// Terakhir` tab stacks several groups.
class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.days, required this.onDetail});

  final List<RiwayatDayGroup> days;
  final VoidCallback onDetail;

  static const TextStyle _dateStyle = TextStyle(
    color: AppColors.neutral900,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const TextStyle _countStyle = TextStyle(
    color: AppColors.neutral500,
    fontSize: 14,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var g = 0; g < days.length; g++) {
      final group = days[g];
      if (g > 0) children.add(const SizedBox(height: 20));
      children
        ..add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(group.date, style: _dateStyle),
              Text(group.taskLabel, style: _countStyle),
            ],
          ),
        )
        ..add(const SizedBox(height: 12));
      for (var e = 0; e < group.entries.length; e++) {
        if (e > 0) children.add(const SizedBox(height: 12));
        children.add(HistoryRow(entry: group.entries[e], onTap: onDetail));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: children,
    );
  }
}

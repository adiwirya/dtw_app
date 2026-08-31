import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_branch_repository.dart';
import 'package:dtw_app/features/tenant/presentation/screens/laporan_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/laporan_charts.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/laporan_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/routed_dio.dart';
import '../../../support/tenant_board.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 3402);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LaporanScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the report header, hero and filter chips', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Laporan'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    expect(find.text('KFC Friend Chicken'), findsOneWidget);
    expect(find.text('Both A12'), findsOneWidget);
    // Filter chips (the tail chips scroll off-screen in the horizontal list).
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Hari'), findsOneWidget);
    // Hero summary card.
    expect(find.byType(ReportSummaryCard), findsOneWidget);
    expect(find.text('Rp 2.450.000'), findsOneWidget);
  });

  testWidgets('renders every breakdown section title', (tester) async {
    await pump(tester);

    for (final title in const [
      'Grafik Penjualan',
      'Jam Ramai Hari Ini',
      'Menu Terlaris',
      'Stok Menipis', // also appears as a low-stock badge → findsWidgets
      'Performa Menu',
      'Jam Ramai',
      'Tren Penjualan',
      'Insight Otomatis',
    ]) {
      expect(find.text(title), findsWidgets, reason: 'missing "$title"');
    }

    // Breakdown content samples.
    expect(find.text('Paket Super Besar'), findsWidgets);
    expect(find.text('Hampir Habis'), findsWidgets);
    expect(find.text('Selasa, 13 Mei 2026'), findsOneWidget);
    expect(find.byType(MenuPerformanceChart), findsOneWidget);
    expect(find.byType(LineChartView), findsNWidgets(2));
  });

  testWidgets('pulling down refetches the tenant branch', (tester) async {
    // A normal phone-sized viewport, not the 3402px one the tests above use
    // to fit the whole report without scrolling — that leaves no scroll
    // room at all, and this test needs genuine overflow for the drag below
    // to register as a pull rather than land on it.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final dio = routedDio({
      '/v1/tenant-branches/$testBranchId': (
        200,
        tenantEnvelope({
          'id': testBranchId,
          'brand_id': 'brand-1',
          'brand_name': 'Janji Jiwa',
          'branch_name': 'Janji Jiwa',
          'area_name': 'Downtown',
          'is_active': true,
          'created_at': '2026-08-07 09:16:37',
        }),
      ),
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(branchScopedStorage()),
          tenantBranchRepositoryProvider.overrideWithValue(
            TenantBranchRepository(dio: dio),
          ),
        ],
        child: const MaterialApp(home: LaporanScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final adapter = dio.httpClientAdapter as RoutedAdapter;
    final before = adapter.requests.length;

    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(0, 300),
      1000,
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final after = adapter.requests.length;
    expect(after, greaterThan(before));
  });
}

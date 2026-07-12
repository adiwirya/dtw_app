import 'package:dtw_app/features/tenant/presentation/screens/laporan_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/laporan_charts.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/laporan_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
}

import 'package:dtw_app/core/widgets/segmented_tab_bar.dart';
import 'package:dtw_app/features/riwayat/data/models/riwayat_models.dart';
import 'package:dtw_app/features/riwayat/presentation/screens/riwayat_screen.dart';
import 'package:dtw_app/features/riwayat/presentation/widgets/history_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(home: RiwayatScreen()),
  );
}

void main() {
  testWidgets('renders the three date tabs from the segmented bar',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.byType(SegmentedTabBar), findsOneWidget);
    expect(find.text('Hari Ini'), findsOneWidget);
    expect(find.text('Kemarin'), findsOneWidget);
    expect(find.text('7 Hari Terakhir'), findsOneWidget);
  });

  testWidgets('Hari Ini tab shows today history + date header', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('12 Mei 2026'), findsOneWidget);
    expect(find.text('3 Tugas'), findsOneWidget);
    expect(find.byType(HistoryRow), findsNWidgets(3));
    expect(find.text('KFC Fried Chicken'), findsOneWidget);
    expect(find.text('J.CO Donuts'), findsOneWidget);
  });

  testWidgets('switching to Kemarin swaps the list in place', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kemarin'));
    await tester.pumpAndSettle();

    expect(find.text('11 Mei 2026'), findsOneWidget);
    expect(find.text('2 Tugas'), findsOneWidget);
    expect(find.byType(HistoryRow), findsNWidgets(2));
    expect(find.text('Solaria'), findsOneWidget);
    expect(find.text('KFC Fried Chicken'), findsNothing);
  });

  testWidgets('7 Hari Terakhir stacks multiple date groups', (tester) async {
    // Tall surface so the whole (lazy) list is laid out at once.
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('7 Hari Terakhir'));
    await tester.pumpAndSettle();

    // Both day groups render (5 rows total across the two dates).
    expect(find.text('12 Mei 2026'), findsOneWidget);
    expect(find.text('11 Mei 2026'), findsOneWidget);
    expect(find.byType(HistoryRow), findsNWidgets(5));
  });

  testWidgets('tapping a row invokes navigation to detail', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HistoryRow(
              entry: const RiwayatEntry(
                time: '10:45',
                statusLabel: 'Selesai',
                tenantName: 'KFC Fried Chicken',
                tableName: 'Meja A-12',
                location: 'Downtown',
              ),
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Detail'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });
}

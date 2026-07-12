import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/segmented_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {double width = 358}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

TextStyle _labelStyle(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!;

void main() {
  const items = [
    SegmentedTabItem(label: 'Hari Ini'),
    SegmentedTabItem(label: 'Kemarin'),
    SegmentedTabItem(label: '7 Hari Terakhir'),
  ];

  group('SegmentedTabBar', () {
    testWidgets('renders every segment label', (tester) async {
      await tester.pumpWidget(
        _host(
          SegmentedTabBar(
            items: items,
            selectedIndex: 0,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Hari Ini'), findsOneWidget);
      expect(find.text('Kemarin'), findsOneWidget);
      expect(find.text('7 Hari Terakhir'), findsOneWidget);
    });

    testWidgets('styles the selected segment active, others inactive',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SegmentedTabBar(
            items: items,
            selectedIndex: 1,
            onChanged: (_) {},
          ),
        ),
      );

      expect(_labelStyle(tester, 'Kemarin').color, AppColors.successGreen);
      expect(_labelStyle(tester, 'Hari Ini').color, AppColors.neutral500);
      expect(_labelStyle(tester, '7 Hari Terakhir').color,
          AppColors.neutral500);
    });

    testWidgets('fires onChanged with the tapped segment index',
        (tester) async {
      int? changed;
      await tester.pumpWidget(
        _host(
          SegmentedTabBar(
            items: items,
            selectedIndex: 0,
            onChanged: (i) => changed = i,
          ),
        ),
      );

      await tester.tap(find.text('7 Hari Terakhir'));
      await tester.pump();
      expect(changed, 2);
    });

    testWidgets('does not fire onChanged when the active segment is tapped',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          SegmentedTabBar(
            items: items,
            selectedIndex: 0,
            onChanged: (_) => calls++,
          ),
        ),
      );

      await tester.tap(find.text('Hari Ini'));
      await tester.pump();
      expect(calls, 0);
    });

    testWidgets('renders optional per-segment icon and badge', (tester) async {
      await tester.pumpWidget(
        _host(
          SegmentedTabBar(
            selectedIndex: 0,
            onChanged: (_) {},
            items: const [
              SegmentedTabItem(
                label: 'Ambil',
                icon: Icons.notifications,
                badge: Text('2'),
              ),
              SegmentedTabItem(label: 'Antar'),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });
}

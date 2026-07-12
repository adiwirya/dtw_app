import 'package:dtw_app/features/performa/presentation/screens/performa_screen.dart';
import 'package:dtw_app/features/performa/presentation/screens/performa_v2_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Self-goldens for the two Performa dashboard variants.
///
/// NOTE: the headless test harness renders text as Ahem boxes and does not
/// load Open Sans, so these goldens intentionally show placeholder glyphs and
/// CANNOT be pixel-diffed against the Figma `reference.png`. They pin layout
/// (structure, spacing, colours, chart bars, card placement) against
/// regressions; fidelity vs. the references was confirmed separately by
/// rendering and comparing screenshots (see the work-item report).
void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget child,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'performa-v1 self-golden',
    (tester) async {
      await pumpScreen(
        tester,
        const PerformaScreen(),
        const Size(390, 844),
      );
      await expectLater(
        find.byType(PerformaScreen),
        matchesGoldenFile('goldens/performa_v1.png'),
      );
    },
    tags: 'golden',
  );

  testWidgets(
    'performa-v2 self-golden',
    (tester) async {
      await pumpScreen(
        tester,
        const PerformaV2Screen(),
        const Size(390, 914),
      );
      await expectLater(
        find.byType(PerformaV2Screen),
        matchesGoldenFile('goldens/performa_v2.png'),
      );
    },
    tags: 'golden',
  );
}

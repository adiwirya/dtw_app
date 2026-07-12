import 'package:dtw_app/features/tenant/presentation/screens/laporan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Self-golden for the tenant `laporan` report dashboard.
///
/// NOTE: the headless test harness renders text as Ahem boxes and does not load
/// Open Sans, so this golden intentionally shows placeholder glyphs and CANNOT
/// be pixel-diffed against the Figma reference (which was only available at
/// half-res). It pins layout (structure, spacing, colours, charts, card
/// placement) against regressions; fidelity vs. the @0.5x reference was
/// confirmed separately (see the work-item report).
void main() {
  testWidgets(
    'laporan self-golden',
    (tester) async {
      // Full frame height (390x3402) so the whole non-scrolled report renders.
      tester.view.physicalSize = const Size(390, 3402);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LaporanScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(LaporanScreen),
        matchesGoldenFile('goldens/laporan.png'),
      );
    },
    tags: 'golden',
  );
}

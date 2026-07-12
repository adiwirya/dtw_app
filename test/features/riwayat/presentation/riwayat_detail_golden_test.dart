import 'package:dtw_app/features/riwayat/presentation/screens/riwayat_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Self-golden for the `detail-riwayat` history-entry detail screen.
///
/// NOTE: the headless harness does not load Open Sans (the cache font), so the
/// golden intentionally shows placeholder text metrics and CANNOT be pixel-
/// diffed against the Figma `reference.png`. The Obra icon font IS loaded (see
/// `flutter_test_config.dart`). This golden pins layout (structure, spacing,
/// colours, card placement) against regressions; fidelity vs. the
/// `detail-riwayat` reference was confirmed separately by rendering and
/// comparing screenshots (see the work-item report).
void main() {
  testWidgets(
    'detail-riwayat self-golden',
    (tester) async {
      // The design frame is 390x950; the body is scrollable so lay it out at
      // the frame height.
      tester.view.physicalSize = const Size(390, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: RiwayatDetailScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(RiwayatDetailScreen),
        matchesGoldenFile('goldens/detail_riwayat.png'),
      );
    },
    tags: 'golden',
  );
}

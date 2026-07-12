import 'package:dtw_app/features/riwayat/presentation/screens/riwayat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Self-goldens for the Riwayat screens.
///
/// NOTE: the headless harness does not load Open Sans (the cache font), so the
/// goldens intentionally show placeholder text metrics and CANNOT be pixel-
/// diffed against the Figma `reference.png`. The Obra icon font IS loaded (see
/// `flutter_test_config.dart`). These goldens pin layout (structure, spacing,
/// colours, card placement) against regressions; fidelity vs. the three
/// references was confirmed separately by rendering and comparing screenshots
/// (see the work-item report).
void main() {
  Future<void> pumpRiwayat(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RiwayatScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'riwayat-hari-ini self-golden',
    (tester) async {
      await pumpRiwayat(tester);
      await expectLater(
        find.byType(RiwayatScreen),
        matchesGoldenFile('goldens/riwayat_hari_ini.png'),
      );
    },
    tags: 'golden',
  );

  testWidgets(
    'riwayat-kemarin self-golden',
    (tester) async {
      await pumpRiwayat(tester);
      await tester.tap(find.text('Kemarin'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(RiwayatScreen),
        matchesGoldenFile('goldens/riwayat_kemarin.png'),
      );
    },
    tags: 'golden',
  );

  testWidgets(
    'riwayat-7-hari self-golden',
    (tester) async {
      await pumpRiwayat(tester);
      await tester.tap(find.text('7 Hari Terakhir'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(RiwayatScreen),
        matchesGoldenFile('goldens/riwayat_7_hari.png'),
      );
    },
    tags: 'golden',
  );
}

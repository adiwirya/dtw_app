import 'package:dtw_app/features/tenant/presentation/screens/admin_status_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Self-goldens for the Admin status screen (`admin-offline` / `admin-online`).
///
/// NOTE: the headless harness does not load Open Sans (the cache font), so the
/// goldens show placeholder text glyphs and CANNOT be pixel-diffed against the
/// Figma `reference.png`. The Obra icon font IS loaded (see
/// `flutter_test_config.dart`). These goldens pin layout (structure, spacing,
/// colours, hero + card placement, online/offline styling) against regressions;
/// fidelity vs. the two references was confirmed separately by rendering and
/// comparing screenshots (see the work-item report).
void main() {
  Future<void> pumpScreen(WidgetTester tester, {required bool online}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: AdminStatusScreen(initialOnline: online)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'admin-offline self-golden',
    (tester) async {
      await pumpScreen(tester, online: false);
      await expectLater(
        find.byType(AdminStatusScreen),
        matchesGoldenFile('goldens/admin_offline.png'),
      );
    },
    tags: 'golden',
  );

  testWidgets(
    'admin-online self-golden',
    (tester) async {
      await pumpScreen(tester, online: true);
      await expectLater(
        find.byType(AdminStatusScreen),
        matchesGoldenFile('goldens/admin_online.png'),
      );
    },
    tags: 'golden',
  );
}

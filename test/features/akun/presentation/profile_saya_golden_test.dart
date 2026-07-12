import 'package:dtw_app/features/akun/presentation/screens/profile_saya_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Self-golden for the `profile-saya` (Profil Saya) screen.
///
/// NOTE: the headless harness does not load Open Sans (the cache font), so the
/// golden intentionally renders placeholder text glyphs and CANNOT be pixel-
/// diffed against the Figma `reference.png`. The Obra icon font IS loaded (see
/// `flutter_test_config.dart`), so the chevron/camera/user glyphs render. This
/// golden pins layout (card structure, field metrics, spacing, colours)
/// against regressions; fidelity vs. the reference was confirmed separately by
/// rendering and comparing screenshots (see the work-item report).
void main() {
  testWidgets(
    'profile-saya self-golden',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1083);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ProfileSayaScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ProfileSayaScreen),
        matchesGoldenFile('goldens/profile_saya.png'),
      );
    },
    tags: 'golden',
  );
}

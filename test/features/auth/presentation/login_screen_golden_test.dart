import 'package:dtw_app/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Self-golden for the login screen.
///
/// NOTE: the headless test harness renders text as Ahem boxes and does not load
/// Open Sans / Pacifico, so these goldens intentionally show placeholder glyphs
/// and CANNOT be pixel-diffed against the Figma `reference.png`. They pin the
/// widget layout (structure, spacing, colours, asset placement) against
/// regressions; fidelity vs. the reference was confirmed separately by running
/// the app and comparing screenshots (see the work-item report).
void main() {
  Future<void> pumpAt390x844(
    WidgetTester tester,
    Widget child,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: child)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'login-default self-golden',
    (tester) async {
      await pumpAt390x844(tester, const LoginScreen());
      await expectLater(
        find.byType(LoginScreen),
        matchesGoldenFile('goldens/login_default.png'),
      );
    },
    tags: 'golden',
  );
}

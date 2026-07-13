import 'package:dtw_app/features/auth/presentation/widgets/role_card.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Self-goldens for the two tenant login steps.
///
/// NOTE: the headless test harness renders text as Ahem boxes and does not load
/// Open Sans / Pacifico, so these goldens intentionally show placeholder glyphs
/// and CANNOT be pixel-diffed against the Figma `reference.png`. They pin the
/// widget layout (structure, spacing, colours, asset placement) against
/// regressions; fidelity vs. the reference was confirmed separately by running
/// the widget and comparing screenshots (see the work-item report).
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
    'tenant login-default self-golden',
    (tester) async {
      await pumpAt390x844(tester, const TenantLoginScreen());
      await expectLater(
        find.byType(TenantLoginScreen),
        matchesGoldenFile('goldens/tenant_login_default.png'),
      );
    },
    tags: 'golden',
  );

  testWidgets(
    'tenant login-tenantt self-golden',
    (tester) async {
      await pumpAt390x844(
        tester,
        const TenantLoginScreen(initialRole: LoginRole.tenan),
      );
      await expectLater(
        find.byType(TenantLoginScreen),
        matchesGoldenFile('goldens/tenant_login_tenantt.png'),
      );
    },
    tags: 'golden',
  );
}

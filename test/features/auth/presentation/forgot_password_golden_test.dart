import 'package:dtw_app/features/auth/presentation/screens/forgot_password_reset_screen.dart';
import 'package:dtw_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:dtw_app/features/auth/presentation/screens/forgot_password_verify_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Self-goldens for the three forgot-password steps (`login-forgot`,
/// `login-forgot-verifikasi`, `login-forgot-password-baru`).
///
/// NOTE: same caveat as `login_screen_golden_test.dart` — the headless
/// harness renders Ahem placeholder glyphs, so these pin layout/spacing/colour
/// regressions only. Fidelity vs. the Figma reference was confirmed by
/// running the app on an emulator and comparing screenshots.
void main() {
  Future<void> pumpAt390x844(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(child: MaterialApp(home: child)));
    await tester.pumpAndSettle();
  }

  testWidgets('login-forgot self-golden', (tester) async {
    await pumpAt390x844(tester, const ForgotPasswordScreen());
    await expectLater(
      find.byType(ForgotPasswordScreen),
      matchesGoldenFile('goldens/login_forgot.png'),
    );
  }, tags: 'golden');

  testWidgets('login-forgot-verifikasi self-golden', (tester) async {
    await pumpAt390x844(
      tester,
      const ForgotPasswordVerifyScreen(email: 'test@example.com'),
    );
    await expectLater(
      find.byType(ForgotPasswordVerifyScreen),
      matchesGoldenFile('goldens/login_forgot_verifikasi.png'),
    );
  }, tags: 'golden');

  testWidgets('login-forgot-password-baru self-golden', (tester) async {
    await pumpAt390x844(tester, const ForgotPasswordResetScreen());
    await expectLater(
      find.byType(ForgotPasswordResetScreen),
      matchesGoldenFile('goldens/login_forgot_password_baru.png'),
    );
  }, tags: 'golden');
}

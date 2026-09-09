import 'package:dtw_app/core/router/app_router.dart' show AppRoutes;
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/auth/presentation/screens/forgot_password_reset_screen.dart';
import 'package:dtw_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:dtw_app/features/auth/presentation/screens/forgot_password_verify_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Minimal router mirroring the forgot-password branch of `app_router.dart`,
/// exercising the 3-step flow without standing up the whole app shell.
GoRouter _router() => GoRouter(
      initialLocation: '/login/forgot-password',
      routes: [
        GoRoute(
          path: '/login',
          name: AppRoutes.login,
          builder: (_, _) => const Scaffold(body: Text('Login')),
          routes: [
            GoRoute(
              path: 'forgot-password',
              name: AppRoutes.forgotPassword,
              builder: (_, _) => const ForgotPasswordScreen(),
              routes: [
                GoRoute(
                  path: 'verify',
                  name: AppRoutes.forgotPasswordVerify,
                  builder: (_, state) => ForgotPasswordVerifyScreen(
                    email: state.extra as String? ?? '',
                  ),
                  routes: [
                    GoRoute(
                      path: 'new-password',
                      name: AppRoutes.forgotPasswordReset,
                      builder: (_, _) => const ForgotPasswordResetScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

Future<void> _pumpRouter(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: _router())),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty email shows a validation message and does not navigate',
      (tester) async {
    await _pumpRouter(tester);

    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
  });

  testWidgets(
    'entering an email and submitting advances to OTP verification with '
    'the email shown',
    (tester) async {
      await _pumpRouter(tester);

      await tester.enterText(
        find.widgetWithText(AppInput, 'Email'),
        'user@dtw.test',
      );
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordVerifyScreen), findsOneWidget);
      expect(
        find.textContaining('user@dtw.test', findRichText: true),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'submitting an incomplete OTP shows a validation message and does not '
    'advance',
    (tester) async {
      await _pumpRouter(tester);
      await tester.enterText(
        find.widgetWithText(AppInput, 'Email'),
        'user@dtw.test',
      );
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('Masukkan 6 digit kode.'), findsOneWidget);
      expect(find.byType(ForgotPasswordVerifyScreen), findsOneWidget);
    },
  );

  testWidgets(
    'a full OTP advances to the new-password step, which returns to login',
    (tester) async {
      await _pumpRouter(tester);
      await tester.enterText(
        find.widgetWithText(AppInput, 'Email'),
        'user@dtw.test',
      );
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      for (final field in find.byType(TextField).evaluate().toList()) {
        await tester.enterText(find.byWidget(field.widget), '1');
      }
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordResetScreen), findsOneWidget);

      final passwordFields = find.byType(AppInput);
      await tester.enterText(passwordFields.at(0), 'newSecret1');
      await tester.enterText(passwordFields.at(1), 'newSecret1');
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
    },
  );

  testWidgets('mismatched passwords show a validation message', (
    tester,
  ) async {
    await _pumpRouter(tester);
    await tester.enterText(
      find.widgetWithText(AppInput, 'Email'),
      'user@dtw.test',
    );
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    for (final field in find.byType(TextField).evaluate().toList()) {
      await tester.enterText(find.byWidget(field.widget), '1');
    }
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    final passwordFields = find.byType(AppInput);
    await tester.enterText(passwordFields.at(0), 'secretA');
    await tester.enterText(passwordFields.at(1), 'secretB');
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(find.text('Password tidak cocok.'), findsOneWidget);
    expect(find.byType(ForgotPasswordResetScreen), findsOneWidget);
  });
}

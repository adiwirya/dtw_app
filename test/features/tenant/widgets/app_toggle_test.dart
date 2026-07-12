import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('AppToggle', () {
    testWidgets('tap fires onChanged with the flipped value', (tester) async {
      bool? received;
      await tester.pumpWidget(
        _host(AppToggle(value: false, onChanged: (v) => received = v)),
      );

      await tester.tap(find.byType(AppToggle));
      await tester.pumpAndSettle();
      expect(received, isTrue);
    });

    testWidgets('on-state track is success green', (tester) async {
      await tester.pumpWidget(
        _host(AppToggle(value: true, onChanged: (_) {})),
      );
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(AppToggle),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.successGreen);
    });

    testWidgets('null onChanged renders disabled and swallows taps',
        (tester) async {
      await tester.pumpWidget(_host(const AppToggle(value: false)));
      // No callback wired; tapping must not throw.
      await tester.tap(find.byType(AppToggle));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

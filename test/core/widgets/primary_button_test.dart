import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {double width = 300}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

Material _material(WidgetTester tester) => tester.widget<Material>(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(Material),
      ),
    );

void main() {
  group('PrimaryButton', () {
    testWidgets('renders the label', (tester) async {
      await tester.pumpWidget(
        _host(PrimaryButton(label: 'Masuk', onPressed: () {})),
      );
      expect(find.text('Masuk'), findsOneWidget);
    });

    testWidgets('is a full-width height-40 success-green pill', (tester) async {
      await tester.pumpWidget(
        _host(PrimaryButton(label: 'Masuk', onPressed: () {})),
      );

      final size = tester.getSize(find.byType(PrimaryButton));
      expect(size.width, 300); // full-width inside the 300px host
      expect(size.height, 40);

      final material = _material(tester);
      expect(material.color, AppColors.successGreen);
      expect(material.borderRadius, BorderRadius.circular(100));
    });

    testWidgets('fires the tap callback', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(PrimaryButton(label: 'Masuk', onPressed: () => taps++)),
      );

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        _host(const PrimaryButton(label: 'Masuk')),
      );

      // Disabled surface differs from the active success green.
      final material = _material(tester);
      expect(material.color, isNot(AppColors.successGreen));

      // Tapping a disabled button does nothing (no exception, no callback).
      await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
      await tester.pump();
    });
  });
}

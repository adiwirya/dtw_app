import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [child] in a fixed-width [MaterialApp] so full-width and height
/// measurements are deterministic against the cached design values.
Widget _host(Widget child, {double width = 300}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

BoxDecoration _fieldDecoration(WidgetTester tester) {
  final container = tester
      .widgetList<Container>(find.byType(Container))
      .firstWhere(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).border != null,
      );
  return container.decoration! as BoxDecoration;
}

EditableText _editable(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

void main() {
  group('AppInput', () {
    testWidgets('renders placeholder and leading icon', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppInput(
            leadingIcon: Icons.person_outline,
            hintText: 'Masukkan username',
          ),
        ),
      );

      expect(find.text('Masukkan username'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('matches cached dimensions: full width, height 40, radius 12, '
        'neutral-100 border', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppInput(
            leadingIcon: Icons.person_outline,
            hintText: 'Masukkan username',
          ),
        ),
      );

      final size = tester.getSize(find.byType(AppInput));
      expect(size.width, 300); // full-width inside the 300px host
      expect(size.height, 40); // no label -> field height only

      final decoration = _fieldDecoration(tester);
      expect(
        decoration.borderRadius,
        BorderRadius.circular(12),
      );
      final border = decoration.border! as Border;
      expect(border.top.color, AppColors.neutral100);
    });

    testWidgets('is not obscured by default', (tester) async {
      await tester.pumpWidget(
        _host(const AppInput(hintText: 'x')),
      );
      expect(_editable(tester).obscureText, isFalse);
    });

    testWidgets('obscureText obscures text and the eye toggle reveals it',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const AppInput(
            leadingIcon: Icons.lock_outline,
            hintText: 'Masukkan password',
            obscureText: true,
          ),
        ),
      );

      expect(_editable(tester).obscureText, isTrue);
      // Obscured -> offers a "reveal" affordance.
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(_editable(tester).obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('explicit trailing overrides the built-in eye toggle',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const AppInput(
            hintText: 'x',
            obscureText: true,
            trailing: Icon(Icons.close),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });

    testWidgets('wires the provided controller', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(AppInput(controller: controller, hintText: 'x')),
      );

      await tester.enterText(find.byType(TextField), 'tenant42');
      expect(controller.text, 'tenant42');
    });

    testWidgets('renders an optional label above the field', (tester) async {
      await tester.pumpWidget(
        _host(const AppInput(label: 'Username', hintText: 'x')),
      );
      expect(find.text('Username'), findsOneWidget);
    });
  });
}

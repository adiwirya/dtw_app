import 'package:dtw_app/features/tenant/presentation/widgets/pickup_code_numpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PickupCodeNumpad', () {
    testWidgets('tapping a digit key calls onDigit with that digit',
        (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        _host(PickupCodeNumpad(onDigit: tapped.add, onBackspace: () {})),
      );

      await tester.tap(find.text('7'));
      await tester.tap(find.text('0'));
      await tester.pump();

      expect(tapped, ['7', '0']);
    });

    testWidgets('tapping backspace calls onBackspace', (tester) async {
      var backspaces = 0;
      await tester.pumpWidget(
        _host(
          PickupCodeNumpad(onDigit: (_) {}, onBackspace: () => backspaces++),
        ),
      );

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();

      expect(backspaces, 1);
    });

    testWidgets('renders 1-9 and 0 with no digit in the bottom-left cell',
        (tester) async {
      await tester.pumpWidget(
        _host(PickupCodeNumpad(onDigit: (_) {}, onBackspace: () {})),
      );

      for (var d = 0; d <= 9; d++) {
        expect(find.text('$d'), findsOneWidget);
      }
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    });
  });
}

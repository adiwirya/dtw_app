import 'package:dtw_app/core/widgets/app_toggle.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/variant_rows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 358, child: child)),
      ),
    );

void main() {
  group('VariantSelectRow', () {
    const data = VariantSelectData(
      name: 'Tingkat Pedas',
      type: VariantType.tunggal,
      optionNames: ['Original', 'Spicy'],
    );

    testWidgets('renders name, type chip, count and option preview',
        (tester) async {
      await tester.pumpWidget(
        _host(
          VariantSelectRow(
            data: data,
            selected: false,
            onSelectedChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Tingkat Pedas'), findsOneWidget);
      expect(find.text('Tunggal'), findsOneWidget);
      expect(find.text('2 Opsi'), findsOneWidget);
      expect(find.text('Original, Spicy'), findsOneWidget);
    });

    testWidgets('ganda type shows the Ganda chip', (tester) async {
      await tester.pumpWidget(
        _host(
          VariantSelectRow(
            data: const VariantSelectData(
              name: 'Extra Topping',
              type: VariantType.ganda,
              optionNames: ['Keju', 'Telur'],
            ),
            selected: false,
            onSelectedChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Ganda'), findsOneWidget);
    });

    testWidgets('tapping the row toggles selection (multi-select)',
        (tester) async {
      bool? selected;
      await tester.pumpWidget(
        _host(
          VariantSelectRow(
            data: data,
            selected: false,
            onSelectedChanged: (v) => selected = v,
          ),
        ),
      );

      await tester.tap(find.text('Tingkat Pedas'));
      await tester.pump();
      expect(selected, isTrue);
    });
  });

  group('VariantRuleToggleRow', () {
    testWidgets('renders title/subtitle and fires onChanged', (tester) async {
      bool? changed;
      await tester.pumpWidget(
        _host(
          VariantRuleToggleRow(
            title: 'Wajib Dipilih',
            subtitle: 'Pelanggan harus memilih salah satu opsi',
            value: false,
            onChanged: (v) => changed = v,
          ),
        ),
      );

      expect(find.text('Wajib Dipilih'), findsOneWidget);
      expect(
        find.text('Pelanggan harus memilih salah satu opsi'),
        findsOneWidget,
      );

      await tester.tap(find.byType(AppToggle));
      await tester.pumpAndSettle();
      expect(changed, isTrue);
    });
  });

  group('VariantOptionRow', () {
    testWidgets('free option renders Gratis', (tester) async {
      await tester.pumpWidget(
        _host(const VariantOptionRow(data: VariantOptionData(name: 'Small'))),
      );
      expect(find.text('Small'), findsOneWidget);
      expect(find.text('Gratis'), findsOneWidget);
    });

    testWidgets('add-on option renders +price', (tester) async {
      await tester.pumpWidget(
        _host(
          const VariantOptionRow(
            data: VariantOptionData(name: 'Medium', addonPrice: 'Rp3.000'),
          ),
        ),
      );
      expect(find.text('+Rp3.000'), findsOneWidget);
    });

    testWidgets('remove button fires onRemove', (tester) async {
      var removed = 0;
      await tester.pumpWidget(
        _host(
          VariantOptionRow(
            data: const VariantOptionData(
              name: 'Medium',
              addonPrice: 'Rp3.000',
            ),
            onRemove: () => removed++,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();
      expect(removed, 1);
    });

    testWidgets('no remove button when onRemove is null', (tester) async {
      await tester.pumpWidget(
        _host(const VariantOptionRow(data: VariantOptionData(name: 'Small'))),
      );
      expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
    });
  });
}

import 'package:dtw_app/core/widgets/app_toggle.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 358, child: child)),
      ),
    );

void main() {
  group('MenuItemCard', () {
    testWidgets('renders name, price, stock and Aktif chip', (tester) async {
      await tester.pumpWidget(
        _host(
          const MenuItemCard(
            data: MenuItemData(
              name: 'Paket Super Besar',
              price: 'Rp35.000',
            ),
          ),
        ),
      );

      expect(find.text('Paket Super Besar'), findsOneWidget);
      expect(find.text('Rp35.000'), findsOneWidget);
      expect(find.text('Stok : Tersedia'), findsOneWidget);
      expect(find.text('Aktif'), findsOneWidget);
      // No discount / popular label by default.
      expect(find.text('Populer'), findsNothing);
    });

    testWidgets('popular=true shows the Populer label', (tester) async {
      await tester.pumpWidget(
        _host(
          const MenuItemCard(
            data: MenuItemData(
              name: 'Paket Super Besar',
              price: 'Rp35.000',
              popular: true,
            ),
          ),
        ),
      );
      expect(find.text('Populer'), findsOneWidget);
    });

    testWidgets('discount shows struck-through original price', (tester) async {
      await tester.pumpWidget(
        _host(
          const MenuItemCard(
            data: MenuItemData(
              name: 'Paket Super Besar',
              price: 'Rp35.000',
              originalPrice: 'Rp45.000',
            ),
          ),
        ),
      );

      expect(find.text('Rp45.000'), findsOneWidget);
      final struck = tester.widget<Text>(find.text('Rp45.000'));
      expect(struck.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('inactive shows Nonaktif chip', (tester) async {
      await tester.pumpWidget(
        _host(
          const MenuItemCard(
            data: MenuItemData(
              name: 'Paket Super Besar',
              price: 'Rp35.000',
              active: false,
            ),
          ),
        ),
      );
      expect(find.text('Nonaktif'), findsOneWidget);
      expect(find.text('Aktif'), findsNothing);
    });

    testWidgets('toggle fires onActiveChanged with flipped value',
        (tester) async {
      bool? changed;
      await tester.pumpWidget(
        _host(
          MenuItemCard(
            data: const MenuItemData(name: 'Paket Hemat', price: 'Rp29.000'),
            onActiveChanged: (v) => changed = v,
          ),
        ),
      );

      await tester.tap(find.byType(AppToggle));
      await tester.pumpAndSettle();
      expect(changed, isFalse);
    });

    testWidgets('whole-card tap fires onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          MenuItemCard(
            data: const MenuItemData(name: 'Paket Hemat', price: 'Rp29.000'),
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.text('Paket Hemat'));
      await tester.pump();
      expect(taps, 1);
    });
  });
}

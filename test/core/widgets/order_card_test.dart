import 'package:dtw_app/core/widgets/order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _baru = OrderCardData(
  orderId: '92842',
  displayNumber: '92842',
  time: '10:31 WIB',
  tenantName: 'KFC Fried Chicken',
  tableName: 'Meja A-12',
  location: 'Downtown',
  customerName: 'Budi Santoso',
  itemCount: 2,
  status: OrderStatus.baru,
);

const _antar = OrderCardData(
  orderId: '92842',
  displayNumber: '92842',
  time: '10:31 WIB',
  tenantName: 'Solaria',
  tableName: 'Meja A-12',
  location: 'Downtown',
  customerName: 'Septian Adityo',
  itemCount: 2,
  status: OrderStatus.antar,
);

const _selesai = OrderCardData(
  orderId: '92842',
  displayNumber: '92842',
  time: '10:31 WIB',
  tenantName: 'KFC Fried Chicken',
  tableName: 'Meja A-12',
  location: 'Downtown',
  customerName: 'Budi Santoso',
  itemCount: 3,
  status: OrderStatus.selesai,
  deliveredDate: '12 Mei 2024',
  deliveredTime: '10:45 WIB',
);

Widget _host(Widget child, {double width = 358}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

void main() {
  group('OrderCard', () {
    testWidgets('baru: renders the common fields + Detail, no action button',
        (tester) async {
      await tester.pumpWidget(_host(const OrderCard(data: _baru)));

      expect(find.text('#92842'), findsOneWidget);
      expect(find.text('10:31 WIB'), findsOneWidget);
      expect(find.text('KFC Fried Chicken'), findsOneWidget);
      expect(find.text('Meja A-12'), findsOneWidget);
      expect(find.text('Downtown'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('2 Item'), findsOneWidget);
      expect(find.text('Detail'), findsOneWidget);

      // No delivery-action affordance in the "baru" state.
      expect(find.text('Sampai dimeja'), findsNothing);
      // No delivered-at footer.
      expect(find.text('Diantar pada'), findsNothing);
    });

    testWidgets('baru: whole-card tap fires onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(OrderCard(data: _baru, onTap: () => taps++)),
      );

      await tester.tap(find.text('KFC Fried Chicken'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('baru: Detail affordance fires onDetailTap', (tester) async {
      var detail = 0;
      var card = 0;
      await tester.pumpWidget(
        _host(
          OrderCard(
            data: _baru,
            onTap: () => card++,
            onDetailTap: () => detail++,
          ),
        ),
      );

      await tester.tap(find.text('Detail'));
      await tester.pump();
      expect(detail, 1);
      expect(card, 0);
    });

    testWidgets('antar: shows the "Sampai dimeja" button + Detail',
        (tester) async {
      await tester.pumpWidget(const _Host(child: OrderCard(data: _antar)));

      expect(find.text('Septian Adityo'), findsOneWidget);
      expect(find.text('Detail'), findsOneWidget);
      expect(find.text('Sampai dimeja'), findsOneWidget);
    });

    testWidgets('antar: primary action button fires onPrimaryAction',
        (tester) async {
      var action = 0;
      await tester.pumpWidget(
        _host(OrderCard(data: _antar, onPrimaryAction: () => action++)),
      );

      await tester.tap(find.text('Sampai dimeja'));
      await tester.pump();
      expect(action, 1);
    });

    testWidgets('antar: primary action label is overridable', (tester) async {
      await tester.pumpWidget(
        _host(
          const OrderCard(data: _antar, primaryActionLabel: 'Selesaikan'),
        ),
      );
      expect(find.text('Selesaikan'), findsOneWidget);
      expect(find.text('Sampai dimeja'), findsNothing);
    });

    testWidgets('selesai: shows Pelanggan + delivered-at, no Detail/button',
        (tester) async {
      await tester.pumpWidget(const _Host(child: OrderCard(data: _selesai)));

      expect(find.text('Pelanggan'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Diantar pada'), findsOneWidget);
      expect(find.text('12 Mei 2024'), findsOneWidget);
      expect(find.text('10:45 WIB'), findsOneWidget);
      expect(find.text('3 Item'), findsOneWidget);

      expect(find.text('Detail'), findsNothing);
      expect(find.text('Sampai dimeja'), findsNothing);
    });

    testWidgets('renders a rounded white card surface', (tester) async {
      await tester.pumpWidget(_host(const OrderCard(data: _baru)));

      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(OrderCard),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, const Color(0xFFFFFFFF));
      expect(
        material.borderRadius,
        BorderRadius.circular(12),
      );
    });
  });
}

/// Taller host so the "antar"/"selesai" cards lay out without overflow.
class _Host extends StatelessWidget {
  const _Host({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 358, child: child),
        ),
      ),
    );
  }
}

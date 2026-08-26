import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _items = [
  OrderLineItem(name: 'Paket Super Besar', price: 'Rp35.000'),
  OrderLineItem(name: 'Es Lemon Tea', price: 'Rp5.000'),
];

const _baru = IncomingOrderData(
  orderId: '92842',
  displayNumber: 'RCP-92842',
  tableName: 'Meja A-12',
  time: '10:36 WIB',
  status: IncomingOrderStatus.baru,
  items: _items,
  total: 'Rp40.000',
);

const _diproses = IncomingOrderData(
  orderId: '92842',
  displayNumber: 'RCP-92842',
  tableName: 'Meja A-12',
  time: '10:36 WIB',
  status: IncomingOrderStatus.diproses,
  items: _items,
  total: 'Rp40.000',
);

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 358, child: child)),
      ),
    );

void main() {
  group('IncomingOrderCard', () {
    testWidgets('baru: renders fields + Tolak/Terima, red status',
        (tester) async {
      await tester.pumpWidget(_host(const IncomingOrderCard(data: _baru)));

      expect(find.text('#RCP-92842'), findsOneWidget);
      expect(find.text('Meja A-12'), findsOneWidget);
      expect(find.text('10:36 WIB'), findsOneWidget);
      expect(find.text('Baru'), findsOneWidget);
      expect(find.text('Paket Super Besar'), findsOneWidget);
      expect(find.text('Rp35.000'), findsOneWidget);
      expect(find.text('Catatan : -'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Rp40.000'), findsOneWidget);
      expect(find.text('Tolak'), findsOneWidget);
      expect(find.text('Terima'), findsOneWidget);
      expect(find.text('Siap Diambil'), findsNothing);
    });

    testWidgets('baru: accept label is overridable (countdown)',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const IncomingOrderCard(data: _baru, acceptLabel: 'Terima (29s)'),
        ),
      );
      expect(find.text('Terima (29s)'), findsOneWidget);
      expect(find.text('Terima'), findsNothing);
    });

    testWidgets('baru: Tolak/Terima fire their callbacks', (tester) async {
      var accepted = 0;
      var rejected = 0;
      await tester.pumpWidget(
        _host(
          IncomingOrderCard(
            data: _baru,
            onAccept: () => accepted++,
            onReject: () => rejected++,
          ),
        ),
      );

      await tester.tap(find.text('Tolak'));
      await tester.tap(find.text('Terima'));
      await tester.pump();
      expect(rejected, 1);
      expect(accepted, 1);
    });

    testWidgets('renders note verbatim when present', (tester) async {
      const withNote = IncomingOrderData(
        orderId: '92842',
        displayNumber: 'RCP-92842',
        tableName: 'Meja A-14',
        time: '10:36 WIB',
        status: IncomingOrderStatus.baru,
        items: [OrderLineItem(name: 'Paket Komplit', price: 'Rp32.000')],
        total: 'Rp32.000',
        note: 'extra sauce ya..',
      );
      await tester.pumpWidget(_host(const IncomingOrderCard(data: withNote)));
      expect(find.text('Catatan : extra sauce ya..'), findsOneWidget);
    });

    testWidgets('diproses: single Siap Diambil button fires onPickupReady',
        (tester) async {
      var pickup = 0;
      await tester.pumpWidget(
        _host(
          IncomingOrderCard(
            data: _diproses,
            onPickupReady: () => pickup++,
          ),
        ),
      );

      expect(find.text('Diproses'), findsOneWidget);
      expect(find.text('Tolak'), findsNothing);
      expect(find.text('Siap Diambil'), findsOneWidget);

      await tester.tap(find.text('Siap Diambil'));
      await tester.pump();
      expect(pickup, 1);
    });
  });

  group('OrderItemAvailabilityRow', () {
    testWidgets('available item shows Tersedia chip + on toggle',
        (tester) async {
      await tester.pumpWidget(
        _host(
          OrderItemAvailabilityRow(
            item: const OrderLineItem(
              name: 'Paket Super Besar',
              price: 'Rp35.000',
            ),
            onAvailabilityChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Paket Super Besar'), findsOneWidget);
      expect(find.text('Qty : 1'), findsOneWidget);
      expect(find.text('Rp35.000'), findsOneWidget);
      expect(find.text('Tersedia'), findsOneWidget);
    });

    testWidgets('unavailable item hides the chip', (tester) async {
      await tester.pumpWidget(
        _host(
          OrderItemAvailabilityRow(
            item: const OrderLineItem(
              name: 'Es Lemon Tea',
              price: 'Rp5.000',
              available: false,
            ),
            onAvailabilityChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Tersedia'), findsNothing);
    });

    testWidgets('toggling fires onAvailabilityChanged with flipped value',
        (tester) async {
      bool? changed;
      await tester.pumpWidget(
        _host(
          OrderItemAvailabilityRow(
            item: const OrderLineItem(name: 'Es Lemon Tea', price: 'Rp5.000'),
            onAvailabilityChanged: (v) => changed = v,
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Ketersediaan Es Lemon Tea'));
      await tester.pumpAndSettle();
      expect(changed, isFalse);
    });
  });
}

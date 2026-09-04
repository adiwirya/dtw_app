import 'package:dtw_app/core/notifications/new_order_alert.dart';
import 'package:dtw_app/features/order/data/models/delivery.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/busboy_board.dart';
import '../../support/tenant_board.dart';

TenantOrder _order({
  String? tableNumber = 'A-12',
  int grandTotal = 45000,
  List<Map<String, dynamic>> items = const [],
}) => TenantOrder.fromJson(
  tenantOrderJson(
    id: 'order-1',
    status: 'PENDING',
    tableNumber: tableNumber,
    grandTotal: grandTotal,
    items: items,
  ),
);

void main() {
  test('reads as table, item count and total', () {
    final alert = NewOrderAlert.fromOrder(
      _order(
        items: [
          tenantOrderItemJson(id: 'i1'),
          tenantOrderItemJson(id: 'i2'),
          tenantOrderItemJson(id: 'i3'),
        ],
      ),
    );

    expect(alert.title, 'Orderan Baru Masuk');
    expect(alert.body, 'Meja A-12 · 3 item · Rp45.000');
    expect(alert.orderId, 'order-1');
  });

  // The `order.created` payload doesn't always carry items — saying "0 item"
  // would be worse than saying nothing.
  test('drops the item count when the payload carries no items', () {
    expect(NewOrderAlert.fromOrder(_order()).body, 'Meja A-12 · Rp45.000');
  });

  test('drops a zero total', () {
    expect(
      NewOrderAlert.fromOrder(_order(grandTotal: 0)).body,
      'Meja A-12',
    );
  });

  // `tableLabel` falls back to the receipt number for orders predating the
  // `table_number` field, so the banner never renders "Meja null".
  test('falls back to the receipt number when there is no table', () {
    final alert = NewOrderAlert.fromOrder(_order(tableNumber: null));

    expect(alert.body, startsWith('Meja RCP-order-1'));
    expect(alert.body, isNot(contains('null')));
  });

  test('two alerts for the same order are equal', () {
    expect(
      NewOrderAlert.fromOrder(_order()),
      NewOrderAlert.fromOrder(_order()),
    );
  });

  group('fromDelivery', () {
    Delivery delivery({
      String tableNumber = 'A12',
      List<Map<String, dynamic>> orders = const [],
    }) => Delivery.fromJson(
      deliveryJson(
        id: 'delivery-1',
        status: 'PENDING_PICKUP',
        tableNumber: tableNumber,
        orders: orders,
      ),
    );

    test('reads as table and item count, with no price part', () {
      final alert = NewOrderAlert.fromDelivery(
        delivery(
          orders: [
            deliveryOrderJson(
              orderId: 'order-1',
              items: [
                deliveryItemJson(productName: 'Es Kopi'),
                deliveryItemJson(productName: 'Nasi Goreng'),
              ],
            ),
          ],
        ),
      );

      expect(alert.title, 'Order Baru Masuk');
      expect(alert.body, 'Meja A12 · 2 item');
      expect(alert.orderId, 'delivery-1');
    });

    // The `delivery.created` payload doesn't always carry items — saying
    // "0 item" would be worse than saying nothing.
    test('drops the item count when the payload carries no items', () {
      expect(NewOrderAlert.fromDelivery(delivery()).body, 'Meja A12');
    });

    test('two alerts for the same delivery are equal', () {
      expect(
        NewOrderAlert.fromDelivery(delivery()),
        NewOrderAlert.fromDelivery(delivery()),
      );
    });
  });
}

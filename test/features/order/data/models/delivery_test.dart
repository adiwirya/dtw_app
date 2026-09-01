import 'package:dtw_app/core/widgets/order_card.dart';
import 'package:dtw_app/features/order/data/models/delivery.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _deliveryJson({
  required String status,
  String? claimedAt,
  String? deliveredAt,
  List<Map<String, dynamic>> orders = const [],
}) => {
  'id': 'delivery-1',
  'receipt_number': 'RCP-delivery-1',
  'status': status,
  'table_number': 'A12',
  'customer_name': 'John',
  'claimed_at': claimedAt,
  'delivered_at': deliveredAt,
  'created_at': '2026-08-27 10:31:00',
  'orders': orders,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('deliveryStatusFromWire', () {
    test('parses every known status', () {
      expect(
        deliveryStatusFromWire('PENDING_PICKUP'),
        DeliveryStatus.pendingPickup,
      );
      expect(deliveryStatusFromWire('CLAIMED'), DeliveryStatus.claimed);
      expect(deliveryStatusFromWire('DELIVERED'), DeliveryStatus.delivered);
    });

    test('throws on an unknown status', () {
      expect(() => deliveryStatusFromWire('WAT'), throwsFormatException);
    });
  });

  group('Delivery.fromJson', () {
    test('parses the confirmed live shape, including a null customer_name',
        () {
      final delivery = Delivery.fromJson(const {
        'id': 'delivery-1',
        'receipt_number': 'RCP-delivery-1',
        'status': 'PENDING_PICKUP',
        'table_number': 'A12',
        'customer_name': null,
        'claimed_at': null,
        'delivered_at': null,
        'created_at': '2026-08-27 10:31:00',
        'orders': [
          {
            'order_id': 'order-1',
            'brand_name': 'Janji Jiwa',
            'items': [
              {'product_name': 'Es Kopi', 'quantity': 2, 'notes': null},
            ],
          },
        ],
      });

      expect(delivery.id, 'delivery-1');
      expect(delivery.receiptNumber, 'RCP-delivery-1');
      expect(delivery.status, DeliveryStatus.pendingPickup);
      expect(delivery.tableNumber, 'A12');
      expect(delivery.customerName, isNull);
      expect(delivery.claimedAt, isNull);
      expect(delivery.deliveredAt, isNull);
      expect(delivery.orders, hasLength(1));
      expect(delivery.orders.single.orderId, 'order-1');
      expect(delivery.orders.single.brandName, 'Janji Jiwa');
      expect(delivery.orders.single.items.single.productName, 'Es Kopi');
      expect(delivery.orders.single.items.single.quantity, 2);
      expect(delivery.orders.single.items.single.notes, isNull);
    });

    test('falls back to receipt_number for id when the API omits it', () {
      final delivery = Delivery.fromJson(const {
        'receipt_number': 'RCP-delivery-1',
        'status': 'PENDING_PICKUP',
        'table_number': 'A12',
        'customer_name': null,
        'claimed_at': null,
        'delivered_at': null,
        'created_at': '2026-08-27 10:31:00',
        'orders': <Map<String, dynamic>>[],
      });

      expect(delivery.id, 'RCP-delivery-1');
      expect(delivery.receiptNumber, 'RCP-delivery-1');
    });

    test('parses claimed_at/delivered_at when present', () {
      final delivery = Delivery.fromJson(
        _deliveryJson(
          status: 'DELIVERED',
          claimedAt: '2026-08-27 10:35:00',
          deliveredAt: '2026-08-27 10:40:00',
        ),
      );

      expect(delivery.claimedAt, DateTime(2026, 8, 27, 10, 35));
      expect(delivery.deliveredAt, DateTime(2026, 8, 27, 10, 40));
    });

    test('itemCount sums items across every bundled order', () {
      final delivery = Delivery.fromJson(
        _deliveryJson(
          status: 'PENDING_PICKUP',
          orders: [
            {
              'order_id': 'order-1',
              'brand_name': 'Janji Jiwa',
              'items': [
                {'product_name': 'Es Kopi', 'quantity': 2, 'notes': null},
              ],
            },
            {
              'order_id': 'order-2',
              'brand_name': 'Solaria',
              'items': [
                {'product_name': 'Nasi Goreng', 'quantity': 1, 'notes': null},
                {'product_name': 'Es Teh', 'quantity': 1, 'notes': null},
              ],
            },
          ],
        ),
      );

      expect(delivery.itemCount, 3);
      expect(delivery.brandNames, 'Janji Jiwa, Solaria');
    });
  });

  group('Delivery.copyWith', () {
    test('overrides only status, keeps every other field', () {
      final delivery = Delivery.fromJson(
        _deliveryJson(status: 'PENDING_PICKUP'),
      );

      final updated = delivery.copyWith(status: DeliveryStatus.claimed);

      expect(updated.status, DeliveryStatus.claimed);
      expect(updated.id, delivery.id);
      expect(updated.receiptNumber, delivery.receiptNumber);
      expect(updated.tableNumber, delivery.tableNumber);
    });
  });

  group('Delivery.toOrderCardData', () {
    test('maps a single-brand delivery, status baru for PENDING_PICKUP', () {
      final delivery = Delivery.fromJson(
        _deliveryJson(
          status: 'PENDING_PICKUP',
          orders: [
            {
              'order_id': 'order-1',
              'brand_name': 'Janji Jiwa',
              'items': [
                {'product_name': 'Es Kopi', 'quantity': 2, 'notes': null},
              ],
            },
          ],
        ),
      );

      final data = delivery.toOrderCardData();

      expect(data.orderId, 'delivery-1');
      expect(data.displayNumber, 'RCP-delivery-1');
      expect(data.tenantName, 'Janji Jiwa');
      expect(data.tableName, 'Meja A12');
      expect(data.customerName, 'John');
      expect(data.itemCount, 1);
      expect(data.status, OrderStatus.baru);
      expect(data.deliveredDate, isNull);
    });

    test('joins brand names for a multi-brand delivery', () {
      final delivery = Delivery.fromJson(
        _deliveryJson(
          status: 'CLAIMED',
          orders: [
            {
              'order_id': 'order-1',
              'brand_name': 'Janji Jiwa',
              'items': <Map<String, dynamic>>[],
            },
            {
              'order_id': 'order-2',
              'brand_name': 'Solaria',
              'items': <Map<String, dynamic>>[],
            },
          ],
        ),
      );

      final data = delivery.toOrderCardData();

      expect(data.tenantName, 'Janji Jiwa, Solaria');
      expect(data.status, OrderStatus.antar);
    });

    test('a null customer_name falls back to a placeholder', () {
      final withoutCustomer = Delivery.fromJson({
        ..._deliveryJson(status: 'PENDING_PICKUP'),
        'customer_name': null,
      });

      expect(withoutCustomer.toOrderCardData().customerName, '-');
    });

    test('formats deliveredDate/deliveredTime for a DELIVERED delivery', () {
      final delivery = Delivery.fromJson(
        _deliveryJson(status: 'DELIVERED', deliveredAt: '2026-08-27 10:45:00'),
      );

      final data = delivery.toOrderCardData();

      expect(data.status, OrderStatus.selesai);
      expect(data.deliveredDate, '27 Agustus 2026');
      expect(data.deliveredTime, '10:45 WIB');
    });
  });

  group('Delivery.toOrderDetail', () {
    test('flattens items across every bundled order', () {
      final delivery = Delivery.fromJson(
        _deliveryJson(
          status: 'PENDING_PICKUP',
          orders: [
            {
              'order_id': 'order-1',
              'brand_name': 'Janji Jiwa',
              'items': [
                {'product_name': 'Es Kopi', 'quantity': 2, 'notes': 'Less ice'},
              ],
            },
            {
              'order_id': 'order-2',
              'brand_name': 'Solaria',
              'items': [
                {'product_name': 'Nasi Goreng', 'quantity': 1, 'notes': null},
              ],
            },
          ],
        ),
      );

      final detail = delivery.toOrderDetail();

      expect(detail.orderId, 'delivery-1');
      expect(detail.displayNumber, 'RCP-delivery-1');
      expect(detail.items, hasLength(2));
      expect(detail.items[0].name, 'Es Kopi');
      expect(detail.items[0].qty, 2);
      expect(detail.items[1].name, 'Nasi Goreng');
      // The API has no price data for busboy deliveries.
      expect(detail.items[0].price, '-');
      expect(detail.total, '-');
      expect(detail.note, 'Less ice');
    });

    test('note falls back to a placeholder when no item has one', () {
      final delivery = Delivery.fromJson(
        _deliveryJson(
          status: 'PENDING_PICKUP',
          orders: [
            {
              'order_id': 'order-1',
              'brand_name': 'Janji Jiwa',
              'items': [
                {'product_name': 'Es Kopi', 'quantity': 1, 'notes': null},
              ],
            },
          ],
        ),
      );

      expect(delivery.toOrderDetail().note, '-');
    });
  });

  group('Delivery.toCompletedOrderDetail', () {
    test('computes waktuAntar/diselesaikan from claimed_at/delivered_at', () {
      final delivery = Delivery.fromJson(
        _deliveryJson(
          status: 'DELIVERED',
          claimedAt: '2026-08-27 10:27:00',
          deliveredAt: '2026-08-27 10:45:00',
        ),
      );

      final detail = delivery.toCompletedOrderDetail();

      expect(detail.orderId, 'delivery-1');
      expect(detail.displayNumber, 'RCP-delivery-1');
      expect(detail.waktuAntar, '18 Menit');
      expect(detail.diselesaikan, '27 Agustus 2026, 10:45');
      expect(detail.flowSteps, hasLength(2));
      expect(detail.flowSteps[0].label, 'Diambil');
      expect(detail.flowSteps[0].timestamp, '27 Agustus 2026, 10:27');
      expect(detail.flowSteps[1].label, 'Sampai Dimeja');
      expect(detail.flowSteps[1].timestamp, '27 Agustus 2026, 10:45');
      // No real per-brand logo on a delivery.
      expect(detail.brandLogoAsset, isNull);
      // The API has no price/total data.
      expect(detail.total, '-');
    });

    test('omits flow steps and shows a placeholder duration when the '
        'timestamps are missing', () {
      final delivery = Delivery.fromJson(_deliveryJson(status: 'CLAIMED'));

      final detail = delivery.toCompletedOrderDetail();

      expect(detail.flowSteps, isEmpty);
      expect(detail.waktuAntar, '-');
      expect(detail.diselesaikan, '-');
    });

    test('infoRows carry the real tenant/table/customer/item-count data', () {
      final delivery = Delivery.fromJson(
        _deliveryJson(
          status: 'DELIVERED',
          orders: [
            {
              'order_id': 'order-1',
              'brand_name': 'Janji Jiwa',
              'items': [
                {'product_name': 'Es Kopi', 'quantity': 2, 'notes': null},
              ],
            },
          ],
        ),
      );

      final rows = delivery.toCompletedOrderDetail().infoRows;

      expect(rows[0].label, 'Tenan');
      expect(rows[0].value, 'Janji Jiwa');
      expect(rows[1].label, 'Meja');
      expect(rows[1].value, 'A12');
      expect(rows[3].label, 'Pelanggan');
      expect(rows[3].value, 'John');
      expect(rows[4].label, 'Jumlah Item');
      expect(rows[4].value, '1 Item');
    });
  });

  group('Delivery.toRiwayatEntry / riwayatDay', () {
    test('carries the real delivery id for detail navigation', () {
      final delivery = Delivery.fromJson(
        _deliveryJson(status: 'DELIVERED', deliveredAt: '2026-08-27 10:45:00'),
      );

      final entry = delivery.toRiwayatEntry();

      expect(entry.id, 'delivery-1');
      expect(entry.time, '10:45 WIB');
      expect(entry.statusLabel, 'Selesai');
      expect(entry.tenantName, delivery.brandNames);
    });

    test('riwayatDay uses delivered_at, falling back to created_at', () {
      final delivered = Delivery.fromJson(
        _deliveryJson(status: 'DELIVERED', deliveredAt: '2026-08-27 23:59:00'),
      );
      expect(delivered.riwayatDay, DateTime(2026, 8, 27));

      final undelivered = Delivery.fromJson(_deliveryJson(status: 'CLAIMED'));
      expect(undelivered.riwayatDay, DateTime(2026, 8, 27));
    });
  });

  group('Delivery.formatDate', () {
    test('formats as "<day> <bulan> <tahun>"', () {
      expect(Delivery.formatDate(DateTime(2026, 8, 27)), '27 Agustus 2026');
    });
  });
}

import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('TenantOrder.fromJson', () {
    test('parses the live GET /v1/orders item shape', () {
      final order = TenantOrder.fromJson(const {
        'id': '76257d18-9f17-41dd-81a3-98404a81eddc',
        'order_group_id': 'ae6322b3-e165-49ca-a6ba-7baf30377cad',
        'branch_id': '0bac8a76-dd70-4345-9d16-742c585e676a',
        'receipt_number': 'RCP-20260807-IOOXVF',
        'grand_total': 21000,
        'order_status': 'PENDING',
        'created_at': '2026-08-07 09:24:08',
        'updated_at': '2026-08-07 09:24:08',
        'items': <dynamic>[],
      });

      expect(order.id, '76257d18-9f17-41dd-81a3-98404a81eddc');
      expect(order.branchId, '0bac8a76-dd70-4345-9d16-742c585e676a');
      expect(order.receiptNumber, 'RCP-20260807-IOOXVF');
      expect(order.grandTotal, 21000);
      expect(order.status, TenantOrderStatus.pending);
      expect(order.createdAt, DateTime(2026, 8, 7, 9, 24, 8));
      expect(order.broadcastEventId, isNull);
    });

    test('a null receipt_number falls back to a placeholder instead of '
        'throwing', () {
      final order = TenantOrder.fromJson(const {
        'id': 'order-1',
        'order_group_id': 'group-1',
        'branch_id': 'branch-1',
        'receipt_number': null,
        'grand_total': 21000,
        'order_status': 'PENDING',
        'created_at': '2026-08-07 09:24:08',
        'updated_at': '2026-08-07 09:24:08',
        'items': <dynamic>[],
      });

      expect(order.receiptNumber, '-');
    });

    test('parses table_number and real line items when the API sends them',
        () {
      final order = TenantOrder.fromJson(const {
        'id': 'order-1',
        'order_group_id': 'group-1',
        'branch_id': 'branch-1',
        'receipt_number': 'RCP-1',
        'table_number': 'A-01',
        'grand_total': 5000,
        'order_status': 'PENDING',
        'created_at': '2026-08-26 07:58:02',
        'updated_at': '2026-08-26 07:58:03',
        'items': [
          {
            'id': 'item-1',
            'order_id': 'order-1',
            'product_id': 'product-1',
            'product_name': 'Sahabat Latte',
            'unit_price': 5000,
            'quantity': 1,
            'subtotal': 5000,
            'status': 'PENDING',
            'notes': null,
            'modifiers': <dynamic>[],
          },
        ],
      });

      expect(order.tableNumber, 'A-01');
      expect(order.items, hasLength(1));
      expect(order.items.single.name, 'Sahabat Latte');
      expect(order.items.single.qty, 1);
      expect(order.items.single.price, 'Rp5.000');
    });

    test('leaves tableNumber null when the API does not send it', () {
      final order = TenantOrder.fromJson(const {
        'id': 'order-1',
        'order_group_id': 'group-1',
        'branch_id': 'branch-1',
        'receipt_number': 'RCP-1',
        'grand_total': 5000,
        'order_status': 'PENDING',
        'created_at': '2026-08-07 09:24:08',
        'updated_at': '2026-08-07 09:24:08',
        'items': <dynamic>[],
      });

      expect(order.tableNumber, isNull);
    });

    test('parses a socket payload carrying broadcast_event_id', () {
      final order = TenantOrder.fromJson(const {
        'id': 'order-1',
        'order_group_id': 'group-1',
        'branch_id': 'branch-1',
        'receipt_number': 'RCP-1',
        'grand_total': 40000,
        'order_status': 'PENDING',
        'created_at': '2026-08-11 10:36:00',
        'updated_at': '2026-08-11 10:36:00',
        'items': <dynamic>[],
        'broadcast_event_id': 123,
      });

      expect(order.broadcastEventId, 123);
    });
  });

  group('TenantOrder.fromBroadcastPayload', () {
    test(
        'unwraps the order/order_group-nested shape of a live order.created '
        'event', () {
      final order = TenantOrder.fromBroadcastPayload(const {
        'broadcast_event_id': 13,
        'order_group': {
          'id': 'group-1',
          'invoice_number': 'INV-1',
          'table_number': 'A-01',
          'customer_name': '231',
          'phone_number': null,
          'is_delivery': false,
          'grand_total': 12000,
          'platform_fee': 2000,
          'delivery_fee': 0,
          'status': 'PAID',
          'area_id': 'area-1',
        },
        'order': {
          'id': 'order-1',
          'order_group_id': 'group-1',
          'branch_id': 'branch-1',
          'receipt_number': 'RCP-1',
          'grand_total': 10000,
          'order_status': 'PENDING',
          // Confirmed live: the nested order's own table_number is null —
          // the real value only lives on the sibling order_group.
          'table_number': null,
          'created_at': '2026-08-26 08:54:20',
          'updated_at': '2026-08-26 08:54:21',
          'items': <dynamic>[],
        },
      });

      expect(order.id, 'order-1');
      expect(order.receiptNumber, 'RCP-1');
      expect(order.tableNumber, 'A-01');
      expect(order.broadcastEventId, 13);
    });

    test("prefers the nested order's own table_number when present", () {
      final order = TenantOrder.fromBroadcastPayload(const {
        'broadcast_event_id': 1,
        'order_group': {'table_number': 'B-02'},
        'order': {
          'id': 'order-1',
          'order_group_id': 'group-1',
          'branch_id': 'branch-1',
          'receipt_number': 'RCP-1',
          'grand_total': 10000,
          'order_status': 'PENDING',
          'table_number': 'A-01',
          'created_at': '2026-08-26 08:54:20',
          'updated_at': '2026-08-26 08:54:21',
          'items': <dynamic>[],
        },
      });

      expect(order.tableNumber, 'A-01');
    });

    test('falls back to fromJson when the payload is already flat '
        '(e.g. a test double emitting the GET /v1/orders item shape)', () {
      final order = TenantOrder.fromBroadcastPayload(const {
        'id': 'order-1',
        'order_group_id': 'group-1',
        'branch_id': 'branch-1',
        'receipt_number': 'RCP-1',
        'grand_total': 10000,
        'order_status': 'PENDING',
        'created_at': '2026-08-26 08:54:20',
        'updated_at': '2026-08-26 08:54:21',
        'items': <dynamic>[],
      });

      expect(order.id, 'order-1');
    });
  });

  group('tenantOrderStatusFromWire / tenantOrderStatusToWire', () {
    test('round-trips every enum value', () {
      for (final status in TenantOrderStatus.values) {
        final wire = tenantOrderStatusToWire(status);
        expect(tenantOrderStatusFromWire(wire), status);
      }
    });

    test('throws on an unknown wire value', () {
      expect(() => tenantOrderStatusFromWire('WAT'), throwsFormatException);
    });
  });

  group('incomingOrderStatusFromBackend', () {
    test('maps pending to baru', () {
      expect(
        incomingOrderStatusFromBackend(TenantOrderStatus.pending),
        IncomingOrderStatus.baru,
      );
    });

    test('maps preparing to diproses', () {
      expect(
        incomingOrderStatusFromBackend(TenantOrderStatus.preparing),
        IncomingOrderStatus.diproses,
      );
    });

    test('maps ready, completed and partialCompleted to selesai', () {
      expect(
        incomingOrderStatusFromBackend(TenantOrderStatus.ready),
        IncomingOrderStatus.selesai,
      );
      expect(
        incomingOrderStatusFromBackend(TenantOrderStatus.completed),
        IncomingOrderStatus.selesai,
      );
      expect(
        incomingOrderStatusFromBackend(TenantOrderStatus.partialCompleted),
        IncomingOrderStatus.selesai,
      );
    });

    test('throws for cancelled (callers must filter cancelled out first)',
        () {
      expect(
        () => incomingOrderStatusFromBackend(TenantOrderStatus.cancelled),
        throwsStateError,
      );
    });
  });

  group('TenantOrder.toIncomingOrderData', () {
    test(
        'maps receiptNumber to tableName, formats time, leaves items empty',
        () {
      final order = TenantOrder.fromJson(const {
        'id': 'order-1',
        'order_group_id': 'group-1',
        'branch_id': 'branch-1',
        'receipt_number': 'RCP-20260807-IOOXVF',
        'grand_total': 21000,
        'order_status': 'PENDING',
        'created_at': '2026-08-07 09:24:08',
        'updated_at': '2026-08-07 09:24:08',
        'items': <dynamic>[],
      });

      final data = order.toIncomingOrderData();

      expect(data.orderId, 'order-1');
      expect(data.tableName, 'RCP-20260807-IOOXVF');
      expect(data.time, '09:24');
      expect(data.status, IncomingOrderStatus.baru);
      expect(data.items, isEmpty);
      expect(data.total, 'Rp21.000');
      expect(data.note, isNull);
    });

    test('prefers tableNumber over receiptNumber, carries real items through',
        () {
      final order = TenantOrder.fromJson(const {
        'id': 'order-1',
        'order_group_id': 'group-1',
        'branch_id': 'branch-1',
        'receipt_number': 'RCP-1',
        'table_number': 'A-01',
        'grand_total': 5000,
        'order_status': 'PENDING',
        'created_at': '2026-08-26 07:58:02',
        'updated_at': '2026-08-26 07:58:03',
        'items': [
          {
            'id': 'item-1',
            'order_id': 'order-1',
            'product_id': 'product-1',
            'product_name': 'Sahabat Latte',
            'unit_price': 5000,
            'quantity': 1,
            'subtotal': 5000,
            'status': 'PENDING',
            'notes': null,
            'modifiers': <dynamic>[],
          },
        ],
      });

      final data = order.toIncomingOrderData();

      expect(data.tableName, 'A-01');
      expect(data.items, hasLength(1));
      expect(data.items.single.name, 'Sahabat Latte');
    });
  });

  group('TenantOrder.copyWith', () {
    test('overrides only status, keeps every other field', () {
      final order = TenantOrder.fromJson(const {
        'id': 'order-1',
        'order_group_id': 'group-1',
        'branch_id': 'branch-1',
        'receipt_number': 'RCP-1',
        'grand_total': 21000,
        'order_status': 'PENDING',
        'created_at': '2026-08-07 09:24:08',
        'updated_at': '2026-08-07 09:24:08',
        'items': <dynamic>[],
      });

      final updated = order.copyWith(status: TenantOrderStatus.preparing);

      expect(updated.status, TenantOrderStatus.preparing);
      expect(updated.id, order.id);
      expect(updated.receiptNumber, order.receiptNumber);
    });
  });
}

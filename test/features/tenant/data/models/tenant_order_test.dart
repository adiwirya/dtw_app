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

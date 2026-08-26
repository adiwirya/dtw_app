import 'package:dtw_app/core/utils/currency.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter/foundation.dart';

/// Mirrors the backend's `order_status` enum (confirmed live: values are
/// UPPER_SNAKE_CASE strings). Distinct from the UI-only [IncomingOrderStatus]
/// — see [incomingOrderStatusFromBackend] for the translation.
enum TenantOrderStatus {
  pending,
  preparing,
  ready,
  completed,
  partialCompleted,
  cancelled,
}

TenantOrderStatus tenantOrderStatusFromWire(String value) => switch (value) {
      'PENDING' => TenantOrderStatus.pending,
      'PREPARING' => TenantOrderStatus.preparing,
      'READY' => TenantOrderStatus.ready,
      'COMPLETED' => TenantOrderStatus.completed,
      'PARTIAL_COMPLETED' => TenantOrderStatus.partialCompleted,
      'CANCELLED' => TenantOrderStatus.cancelled,
      _ => throw FormatException('Unknown order_status: $value'),
    };

String tenantOrderStatusToWire(TenantOrderStatus status) => switch (status) {
      TenantOrderStatus.pending => 'PENDING',
      TenantOrderStatus.preparing => 'PREPARING',
      TenantOrderStatus.ready => 'READY',
      TenantOrderStatus.completed => 'COMPLETED',
      TenantOrderStatus.partialCompleted => 'PARTIAL_COMPLETED',
      TenantOrderStatus.cancelled => 'CANCELLED',
    };

/// Translates a backend status into the three UI sub-tabs. [TenantOrder]
/// lists are filtered to exclude [TenantOrderStatus.cancelled] before this
/// is ever called (see `TenantOrderRepository`/`TenantOrderBoard`) — calling
/// it with `cancelled` is a programming error, not a case to render.
IncomingOrderStatus incomingOrderStatusFromBackend(TenantOrderStatus status) {
  switch (status) {
    case TenantOrderStatus.pending:
      return IncomingOrderStatus.baru;
    case TenantOrderStatus.preparing:
      return IncomingOrderStatus.diproses;
    case TenantOrderStatus.ready:
    case TenantOrderStatus.completed:
    case TenantOrderStatus.partialCompleted:
      return IncomingOrderStatus.selesai;
    case TenantOrderStatus.cancelled:
      throw StateError(
        'cancelled orders must be filtered out before status mapping',
      );
  }
}

/// A tenant-branch order, as returned by `GET /v1/orders` or delivered live
/// via the `order.created` Reverb event.
///
/// [tableNumber] and real [items] were added to the live API after the
/// 2026-08-11 design doc's "known gap" (that shape had neither) — confirmed
/// live on 2026-08-26. [toIncomingOrderData] prefers [tableNumber], falling
/// back to [receiptNumber] only for orders from before that field existed.
@immutable
class TenantOrder {
  const TenantOrder({
    required this.id,
    required this.orderGroupId,
    required this.branchId,
    required this.receiptNumber,
    required this.grandTotal,
    required this.status,
    required this.createdAt,
    required this.items,
    this.tableNumber,
    this.broadcastEventId,
  });

  factory TenantOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? const [];
    return TenantOrder(
      id: json['id'] as String,
      orderGroupId: json['order_group_id'] as String,
      branchId: json['branch_id'] as String,
      // Confirmed live: despite the documented shape, the API can send a
      // null receipt_number (e.g. not yet generated) — one bad record must
      // not take down the whole board's fetch.
      receiptNumber: json['receipt_number'] as String? ?? '-',
      tableNumber: json['table_number'] as String?,
      grandTotal: (json['grand_total'] as num).toInt(),
      status: tenantOrderStatusFromWire(json['order_status'] as String),
      createdAt:
          DateTime.parse((json['created_at'] as String).replaceFirst(' ', 'T')),
      items: [
        for (final item in rawItems.cast<Map<String, dynamic>>())
          OrderLineItem(
            name: item['product_name'] as String,
            price: formatRupiah((item['subtotal'] as num).round()),
            qty: (item['quantity'] as num).toInt(),
          ),
      ],
      broadcastEventId: json['broadcast_event_id'] as int?,
    );
  }

  /// Parses a live `order.created` socket event or a
  /// `GET /v1/broadcast/replay` item's `payload` — both wrap the order
  /// under an `order` key, sibling to `order_group` (which carries
  /// `table_number` when the order's own copy is null) and the top-level
  /// `broadcast_event_id`, unlike `GET /v1/orders`'s flat item shape.
  /// Falls back to [TenantOrder.fromJson] when the payload is already flat,
  /// so a caller that isn't sure which shape it has can always use this.
  factory TenantOrder.fromBroadcastPayload(Map<String, dynamic> payload) {
    final rawOrder = payload['order'];
    if (rawOrder is! Map) return TenantOrder.fromJson(payload);

    final order = Map<String, dynamic>.of(rawOrder.cast<String, dynamic>());
    final orderGroup = payload['order_group'];
    if (order['table_number'] == null && orderGroup is Map) {
      order['table_number'] = orderGroup['table_number'];
    }
    order['broadcast_event_id'] ??= payload['broadcast_event_id'];
    return TenantOrder.fromJson(order);
  }

  final String id;
  final String orderGroupId;
  final String branchId;
  final String receiptNumber;

  /// Real table/order number, e.g. `A-01` — added to the live API after the
  /// original "no table name" gap. Null for orders fetched before this field
  /// existed.
  final String? tableNumber;
  final int grandTotal;
  final TenantOrderStatus status;
  final DateTime createdAt;
  final List<OrderLineItem> items;
  final int? broadcastEventId;

  TenantOrder copyWith({TenantOrderStatus? status}) => TenantOrder(
        id: id,
        orderGroupId: orderGroupId,
        branchId: branchId,
        receiptNumber: receiptNumber,
        tableNumber: tableNumber,
        grandTotal: grandTotal,
        status: status ?? this.status,
        createdAt: createdAt,
        items: items,
        broadcastEventId: broadcastEventId,
      );

  IncomingOrderData toIncomingOrderData() {
    final hh = createdAt.hour.toString().padLeft(2, '0');
    final mm = createdAt.minute.toString().padLeft(2, '0');
    return IncomingOrderData(
      orderId: id,
      displayNumber: receiptNumber,
      tableName: tableNumber ?? receiptNumber,
      time: '$hh:$mm',
      status: incomingOrderStatusFromBackend(status),
      items: items,
      total: formatRupiah(grandTotal),
    );
  }
}

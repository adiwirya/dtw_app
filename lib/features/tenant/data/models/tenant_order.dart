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
/// **Known gap (see the 2026-08-11 design doc):** the live API's order
/// shape has no table name and an always-empty `items` array — there is no
/// confirmed source for either yet. [toIncomingOrderData] fills the UI's
/// `tableName` slot with [receiptNumber] (real data, repurposed) and always
/// renders an empty item list until the real shape is found.
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
    this.broadcastEventId,
  });

  factory TenantOrder.fromJson(Map<String, dynamic> json) {
    return TenantOrder(
      id: json['id'] as String,
      orderGroupId: json['order_group_id'] as String,
      branchId: json['branch_id'] as String,
      receiptNumber: json['receipt_number'] as String,
      grandTotal: (json['grand_total'] as num).toInt(),
      status: tenantOrderStatusFromWire(json['order_status'] as String),
      createdAt:
          DateTime.parse((json['created_at'] as String).replaceFirst(' ', 'T')),
      broadcastEventId: json['broadcast_event_id'] as int?,
    );
  }

  final String id;
  final String orderGroupId;
  final String branchId;
  final String receiptNumber;
  final int grandTotal;
  final TenantOrderStatus status;
  final DateTime createdAt;
  final int? broadcastEventId;

  TenantOrder copyWith({TenantOrderStatus? status}) => TenantOrder(
        id: id,
        orderGroupId: orderGroupId,
        branchId: branchId,
        receiptNumber: receiptNumber,
        grandTotal: grandTotal,
        status: status ?? this.status,
        createdAt: createdAt,
        broadcastEventId: broadcastEventId,
      );

  IncomingOrderData toIncomingOrderData() {
    final hh = createdAt.hour.toString().padLeft(2, '0');
    final mm = createdAt.minute.toString().padLeft(2, '0');
    return IncomingOrderData(
      orderId: id,
      tableName: receiptNumber,
      time: '$hh:$mm',
      status: incomingOrderStatusFromBackend(status),
      items: const [],
      total: formatRupiah(grandTotal),
    );
  }
}

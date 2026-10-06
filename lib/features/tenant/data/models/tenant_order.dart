import 'package:dtw_app/core/utils/currency.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter/foundation.dart';

/// Mirrors the backend's `order_status` enum (confirmed live: values are
/// UPPER_SNAKE_CASE strings): `PENDING → PREPARING → READY → DELIVERING →
/// COMPLETED / PARTIAL_COMPLETED` (`CANCELLED` off to the side). Distinct from
/// the UI-only [IncomingOrderStatus]
/// — see [incomingOrderStatusFromBackend] for the translation.
enum TenantOrderStatus {
  pending,
  preparing,
  ready,
  delivering,
  completed,
  partialCompleted,
  cancelled,
}

TenantOrderStatus tenantOrderStatusFromWire(String value) => switch (value) {
      'PENDING' => TenantOrderStatus.pending,
      'PREPARING' => TenantOrderStatus.preparing,
      'READY' => TenantOrderStatus.ready,
      'DELIVERING' => TenantOrderStatus.delivering,
      'COMPLETED' => TenantOrderStatus.completed,
      'PARTIAL_COMPLETED' => TenantOrderStatus.partialCompleted,
      'CANCELLED' => TenantOrderStatus.cancelled,
      _ => throw FormatException('Unknown order_status: $value'),
    };

String tenantOrderStatusToWire(TenantOrderStatus status) => switch (status) {
      TenantOrderStatus.pending => 'PENDING',
      TenantOrderStatus.preparing => 'PREPARING',
      TenantOrderStatus.ready => 'READY',
      TenantOrderStatus.delivering => 'DELIVERING',
      TenantOrderStatus.completed => 'COMPLETED',
      TenantOrderStatus.partialCompleted => 'PARTIAL_COMPLETED',
      TenantOrderStatus.cancelled => 'CANCELLED',
    };

/// How a tenant order reaches the customer — a busboy carries it
/// ([delivery]), or the customer collects it themselves at the counter
/// ([selfPickup]). See `GLOSSARY.md`'s "Fulfillment Type" entry: this is a
/// mobile-app-only naming choice over the real `order_group.is_delivery`
/// boolean, deliberately not called "pickup" alone — that word already
/// means something unrelated on the busboy-delivery side
/// ([TenantOrderStatus] has no `pendingPickup` value itself, but the
/// parallel busboy-delivery status of the same name is a different concept
/// entirely; see the Glossary).
enum OrderFulfillmentType { delivery, selfPickup }

/// Maps the real `order_group.is_delivery` boolean to [OrderFulfillmentType].
/// `null` (no `order_group` to read it from at all — see the Spec's Blocking
/// Questions for why `GET /v1/orders`'s flat shape can't provide this today)
/// defaults to [OrderFulfillmentType.delivery]: the safer wrong guess, since
/// it only means a real self-pickup order fetched via the initial/REST path
/// behaves like it does today (straight to "Selesai") rather than wrongly
/// demanding a pickup code on what might actually be a delivery order.
OrderFulfillmentType orderFulfillmentTypeFromIsDelivery({bool? isDelivery}) =>
    isDelivery == false
        ? OrderFulfillmentType.selfPickup
        : OrderFulfillmentType.delivery;

/// Translates a backend status into the three UI sub-tabs. [TenantOrder]
/// lists are filtered to exclude [TenantOrderStatus.cancelled] before this
/// is ever called (see `TenantOrderRepository`/`TenantOrderBoard`) — calling
/// it with `cancelled` is a programming error, not a case to render.
///
/// [TenantOrderStatus.ready] is the one fulfillment-dependent case: a
/// delivery order is done from the tenant's side the moment it's ready (a
/// busboy takes over), but a self-pickup order still needs its pickup code
/// verified before it's really finished — so it stays in "Diproses" (see
/// `IncomingOrderCard`'s "Verifikasi Pickup" action) until
/// [TenantOrderStatus.completed].
IncomingOrderStatus incomingOrderStatusFromBackend(
  TenantOrderStatus status,
  OrderFulfillmentType fulfillmentType,
) {
  switch (status) {
    case TenantOrderStatus.pending:
      return IncomingOrderStatus.baru;
    case TenantOrderStatus.preparing:
      return IncomingOrderStatus.diproses;
    case TenantOrderStatus.ready:
      return fulfillmentType == OrderFulfillmentType.selfPickup
          ? IncomingOrderStatus.diproses
          : IncomingOrderStatus.selesai;
    // A busboy has claimed it — the tenant's part is over.
    case TenantOrderStatus.delivering:
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
    this.customerName,
    this.broadcastEventId,
    this.fulfillmentType = OrderFulfillmentType.delivery,
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
      customerName: json['customer_name'] as String?,
      grandTotal: (json['grand_total'] as num).toInt(),
      status: tenantOrderStatusFromWire(json['order_status'] as String),
      createdAt:
          DateTime.parse((json['created_at'] as String).replaceFirst(' ', 'T')),
      items: [
        for (final item in rawItems.cast<Map<String, dynamic>>())
          OrderLineItem(
            id: item['id'] as String,
            name: item['product_name'] as String,
            price: formatRupiah((item['subtotal'] as num).round()),
            subtotal: (item['subtotal'] as num).round(),
            qty: (item['quantity'] as num).toInt(),
          ),
      ],
      broadcastEventId: json['broadcast_event_id'] as int?,
      // The flat GET /v1/orders shape has no `is_delivery` of its own — see
      // orderFulfillmentTypeFromIsDelivery's doc and the Spec's Blocking
      // Questions. `fromBroadcastPayload` threads its `order_group`'s
      // `is_delivery` in under this same key before delegating here.
      fulfillmentType: orderFulfillmentTypeFromIsDelivery(
        isDelivery: json['is_delivery'] as bool?,
      ),
    );
  }

  /// Parses a live `order.created` socket event or a
  /// `GET /v1/broadcast/replay` item's `payload` — both wrap the order
  /// under an `order` key, sibling to `order_group` (which carries
  /// `table_number` when the order's own copy is null, and `is_delivery` —
  /// see [OrderFulfillmentType] — which the order itself never carries at
  /// all) and the top-level `broadcast_event_id`, unlike `GET /v1/orders`'s
  /// flat item shape. Falls back to [TenantOrder.fromJson] when the payload
  /// is already flat, so a caller that isn't sure which shape it has can
  /// always use this.
  factory TenantOrder.fromBroadcastPayload(Map<String, dynamic> payload) {
    final rawOrder = payload['order'];
    if (rawOrder is! Map) return TenantOrder.fromJson(payload);

    final order = Map<String, dynamic>.of(rawOrder.cast<String, dynamic>());
    final orderGroup = payload['order_group'];
    if (order['table_number'] == null && orderGroup is Map) {
      order['table_number'] = orderGroup['table_number'];
    }
    if (orderGroup is Map) {
      order['is_delivery'] = orderGroup['is_delivery'];
      order['customer_name'] ??= orderGroup['customer_name'];
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

  /// The customer's name, printed on the bon. Not in the live
  /// `GET /v1/orders` shape as of 2026-10-06 — read from `customer_name`
  /// (the key the order group uses) when the API starts sending it, `null`
  /// until then.
  final String? customerName;
  final int grandTotal;
  final TenantOrderStatus status;
  final DateTime createdAt;
  final List<OrderLineItem> items;
  final int? broadcastEventId;

  /// How this order reaches the customer — see [OrderFulfillmentType].
  final OrderFulfillmentType fulfillmentType;

  TenantOrder copyWith({TenantOrderStatus? status}) => TenantOrder(
        id: id,
        orderGroupId: orderGroupId,
        branchId: branchId,
        receiptNumber: receiptNumber,
        tableNumber: tableNumber,
        customerName: customerName,
        grandTotal: grandTotal,
        status: status ?? this.status,
        createdAt: createdAt,
        items: items,
        broadcastEventId: broadcastEventId,
        fulfillmentType: fulfillmentType,
      );

  /// The human-facing table label: the real [tableNumber] when the API has
  /// one, else [receiptNumber].
  ///
  /// Single-sourced deliberately. This used to be computed inline in
  /// `toIncomingOrderData` AND separately in `TenantRejectOrderScreen`, which
  /// still showed the receipt number after `table_number` was added to the API
  /// — so the Order card said `A-01` while the reject screen for the same
  /// order said `RCP-...`.
  String get tableLabel => tableNumber ?? receiptNumber;

  IncomingOrderData toIncomingOrderData() {
    final hh = createdAt.hour.toString().padLeft(2, '0');
    final mm = createdAt.minute.toString().padLeft(2, '0');
    return IncomingOrderData(
      orderId: id,
      displayNumber: receiptNumber,
      tableName: tableLabel,
      time: '$hh:$mm',
      status: incomingOrderStatusFromBackend(status, fulfillmentType),
      items: items,
      total: formatRupiah(grandTotal),
      fulfillmentType: fulfillmentType,
      readyForPickup: status == TenantOrderStatus.ready,
    );
  }
}

import 'package:dtw_app/core/utils/currency.dart';
import 'package:dtw_app/features/order/data/models/delivery.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:flutter/foundation.dart';

/// What a session is told when one new order/delivery arrives — the same
/// copy feeds the in-app banner (tenant) or tray notification (both flavors)
/// and the chime, so they can't drift. [NewOrderAlert.fromOrder] builds it
/// for a tenant's new `TenantOrder`; [NewOrderAlert.fromDelivery] for a
/// busboy's new [Delivery] to pick up.
@immutable
class NewOrderAlert {
  const NewOrderAlert({
    required this.orderId,
    required this.title,
    required this.body,
  });

  /// Builds the alert for [order].
  ///
  /// The body is `Meja A-12 · 3 item · Rp45.000`, dropping any part that has
  /// nothing to say: an order whose items haven't been delivered in the
  /// broadcast payload shows the table and total rather than `0 item`.
  factory NewOrderAlert.fromOrder(TenantOrder order) {
    final parts = [
      'Meja ${order.tableLabel}',
      if (order.items.isNotEmpty) '${order.items.length} item',
      if (order.grandTotal > 0) formatRupiah(order.grandTotal),
    ];
    return NewOrderAlert(
      orderId: order.id,
      title: 'Orderan Baru Masuk',
      body: parts.join(' · '),
    );
  }

  /// Builds the alert for a newly-created busboy [delivery].
  ///
  /// The body is `Meja A12 · 3 item`, dropping the item count when the
  /// `delivery.created` payload carries none — same "don't fabricate a
  /// zero" rule as [NewOrderAlert.fromOrder]. A delivery has no total of
  /// its own (see
  /// `Delivery.toOrderDetail`), so unlike a tenant order there is no price
  /// part to show.
  factory NewOrderAlert.fromDelivery(Delivery delivery) {
    final parts = [
      'Meja ${delivery.tableNumber}',
      if (delivery.itemCount > 0) '${delivery.itemCount} item',
    ];
    return NewOrderAlert(
      orderId: delivery.id,
      title: 'Order Baru Masuk',
      body: parts.join(' · '),
    );
  }

  /// The order/delivery this announces — also the notification id, so two
  /// events for the same one replace rather than stack.
  final String orderId;

  /// Headline, e.g. `Orderan Baru Masuk`.
  final String title;

  /// Supporting line, e.g. `Meja A-12 · 3 item · Rp45.000`.
  final String body;

  @override
  bool operator ==(Object other) =>
      other is NewOrderAlert &&
      other.orderId == orderId &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(orderId, title, body);

  @override
  String toString() => 'NewOrderAlert($orderId, $title, $body)';
}

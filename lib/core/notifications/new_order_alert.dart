import 'package:dtw_app/core/utils/currency.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:flutter/foundation.dart';

/// What the tenant is told when one new order arrives — the same copy feeds
/// the in-app banner and the Android notification, so the two can't drift.
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

  /// The order this announces — also the notification id, so two events for
  /// the same order replace rather than stack.
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

import 'package:dtw_app/core/widgets/order_card.dart';
import 'package:flutter/foundation.dart';

/// One coloured summary stat in the floating header card on the Order home
/// (`menu-order-baru` `Frame 2442` ×3): a large tinted [value] over a grey
/// [label], with an optional trailing rating star.
@immutable
class OrderHeaderStat {
  const OrderHeaderStat({
    required this.value,
    required this.label,
    required this.color,
    this.showStar = false,
  });

  /// Headline, e.g. `95%`, `12`, `4.9`.
  final String value;

  /// Supporting caption under the value, e.g. `Ketepatan Waktu`.
  final String label;

  /// ARGB colour for [value]; resolved against `AppColors` at the seam.
  final int color;

  /// Whether an amber rating star trails the value (the rating stat).
  final bool showStar;
}

/// One line item in an order's `Ringkasan Pesanan` (`menu-order-baru-2`).
@immutable
class OrderLineItem {
  const OrderLineItem({
    required this.qty,
    required this.name,
    required this.price,
  });

  /// Quantity, rendered as `<qty>x`.
  final int qty;

  /// Menu item name, e.g. `Paket Super Besar`.
  final String name;

  /// Formatted price, e.g. `Rp35.000`.
  final String price;
}

/// Full order detail backing the `menu-order-baru-2` ("Detail Pesanan") screen:
/// the order's tenant/table/customer header, its itemised summary and total,
/// and the customer note.
///
/// Open question: this should be replaced with the mapped domain entity once
/// the order data source / API contract is decided (see work item L3).
@immutable
class OrderDetail {
  const OrderDetail({
    required this.orderId,
    required this.displayNumber,
    required this.time,
    required this.tenantName,
    required this.tableName,
    required this.location,
    required this.customerName,
    required this.itemCount,
    required this.items,
    required this.total,
    required this.note,
    required this.status,
  });

  /// The real order id — what the "Ambil Pesanan" claim action targets.
  /// Never shown to the busboy directly.
  final String orderId;

  /// Human-friendly order reference shown as `#<displayNumber>` (the receipt
  /// number — not [orderId]).
  final String displayNumber;

  /// Created/quoted time, e.g. `10:31 WIB`.
  final String time;

  /// Source tenant name, e.g. `KFC Fried Chicken`.
  final String tenantName;

  /// Destination table label, e.g. `Meja A-12`.
  final String tableName;

  /// Destination area/zone, e.g. `Downtown`.
  final String location;

  /// Customer name, e.g. `Budi Santoso`.
  final String customerName;

  /// Number of line items. Rendered as `<itemCount> Item`.
  final int itemCount;

  /// Ordered line items.
  final List<OrderLineItem> items;

  /// Formatted grand total, e.g. `Rp40.000`.
  final String total;

  /// Free-text customer note; `-` when empty (matches the reference).
  final String note;

  /// The underlying delivery's board status — e.g. hides the "Ambil Pesanan"
  /// CTA once it's no longer [OrderStatus.baru] (already claimed elsewhere).
  final OrderStatus status;
}

/// The three Menu Order sub-tab lists, keyed by [OrderStatus].
///
/// The Baru → Antar → Selesai movement is a UI-only mock transition (Open
/// Questions 2–5): the board notifier's `takeBaru` promotes a Baru order to
/// Antar; `deliverAntar` promotes an Antar order to Selesai. No backend is
/// involved.
@immutable
class OrderBoard {
  const OrderBoard({
    required this.baru,
    required this.antar,
    required this.selesai,
  });

  /// Orders awaiting pickup (the "Ambil" sub-tab).
  final List<OrderCardData> baru;

  /// Orders in delivery (the "Antar" sub-tab).
  final List<OrderCardData> antar;

  /// Delivered orders (the "Selesai" sub-tab).
  final List<OrderCardData> selesai;

  /// The list for [status].
  List<OrderCardData> listFor(OrderStatus status) => switch (status) {
        OrderStatus.baru => baru,
        OrderStatus.antar => antar,
        OrderStatus.selesai => selesai,
      };

  OrderBoard copyWith({
    List<OrderCardData>? baru,
    List<OrderCardData>? antar,
    List<OrderCardData>? selesai,
  }) {
    return OrderBoard(
      baru: baru ?? this.baru,
      antar: antar ?? this.antar,
      selesai: selesai ?? this.selesai,
    );
  }
}

import 'package:dtw_app/core/models/completed_order_detail.dart';
import 'package:dtw_app/core/widgets/order_card.dart';
import 'package:dtw_app/features/order/data/models/order_models.dart';
import 'package:dtw_app/features/riwayat/data/models/riwayat_models.dart';
import 'package:flutter/material.dart';
import 'package:obra_icons/obra_icons.dart';

/// Mirrors the busboy delivery API's `status` enum.
enum DeliveryStatus { pendingPickup, claimed, delivered }

DeliveryStatus deliveryStatusFromWire(String value) => switch (value) {
      'PENDING_PICKUP' => DeliveryStatus.pendingPickup,
      'CLAIMED' => DeliveryStatus.claimed,
      'DELIVERED' => DeliveryStatus.delivered,
      _ => throw FormatException('Unknown delivery status: $value'),
    };

OrderStatus _orderStatusFor(DeliveryStatus status) => switch (status) {
      DeliveryStatus.pendingPickup => OrderStatus.baru,
      DeliveryStatus.claimed => OrderStatus.antar,
      DeliveryStatus.delivered => OrderStatus.selesai,
    };

/// One line item of one [DeliveryOrder].
@immutable
class DeliveryItem {
  const DeliveryItem({
    required this.productName,
    required this.quantity,
    this.notes,
  });

  factory DeliveryItem.fromJson(Map<String, dynamic> json) => DeliveryItem(
        productName: json['product_name'] as String,
        quantity: (json['quantity'] as num).toInt(),
        notes: json['notes'] as String?,
      );

  final String productName;
  final int quantity;
  final String? notes;
}

/// One brand's order within a [Delivery] — a delivery can bundle orders from
/// more than one brand for the same table.
@immutable
class DeliveryOrder {
  const DeliveryOrder({
    required this.orderId,
    required this.brandName,
    required this.items,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) => DeliveryOrder(
        orderId: json['order_id'] as String,
        brandName: json['brand_name'] as String,
        items: [
          for (final item
              in (json['items'] as List).cast<Map<String, dynamic>>())
            DeliveryItem.fromJson(item),
        ],
      );

  final String orderId;
  final String brandName;
  final List<DeliveryItem> items;
}

/// A busboy delivery — one table-level pickup/delivery task, possibly
/// bundling orders from multiple brands (`GET /api/v1/busboy/deliveries`).
@immutable
class Delivery {
  const Delivery({
    required this.id,
    required this.receiptNumber,
    required this.status,
    required this.tableNumber,
    required this.customerName,
    required this.createdAt,
    required this.orders,
    this.claimedAt,
    this.deliveredAt,
  });

  // `id` is the real identifier — claim/complete
  // (`/v1/busboy/deliveries/{id}/...`) and every board lookup key off it.
  // `receipt_number` is display-only (`#<receiptNumber>` on the card/detail
  // views) — never sent back to the API.
  //
  // `id` falls back to `receipt_number` when absent: the live payload has
  // been observed without an `id` field at all (crashed every fetch with a
  // null-cast error) — this keeps the board working either way instead of
  // hard-failing on whichever shape the backend happens to send.
  factory Delivery.fromJson(Map<String, dynamic> json) {
    final receiptNumber = json['receipt_number'] as String;
    return Delivery(
      id: (json['id'] as String?) ?? receiptNumber,
      receiptNumber: receiptNumber,
      status: deliveryStatusFromWire(json['status'] as String),
      tableNumber: json['table_number'] as String,
      customerName: json['customer_name'] as String?,
      claimedAt: _parseNullable(json['claimed_at']),
      deliveredAt: _parseNullable(json['delivered_at']),
      createdAt: DateTime.parse(
        (json['created_at'] as String).replaceFirst(' ', 'T'),
      ),
      orders: [
        for (final order
            in (json['orders'] as List).cast<Map<String, dynamic>>())
          DeliveryOrder.fromJson(order),
      ],
    );
  }

  final String id;
  final String receiptNumber;
  final DeliveryStatus status;
  final String tableNumber;
  final String? customerName;
  final DateTime? claimedAt;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final List<DeliveryOrder> orders;

  static DateTime? _parseNullable(Object? value) {
    if (value is! String) return null;
    return DateTime.parse(value.replaceFirst(' ', 'T'));
  }

  int get itemCount =>
      orders.fold(0, (sum, order) => sum + order.items.length);

  /// The brand names across every bundled order, comma-joined — the API has
  /// no single "tenant" field on a delivery since it can span brands.
  String get brandNames => orders.map((o) => o.brandName).join(', ');

  Delivery copyWith({DeliveryStatus? status}) => Delivery(
        id: id,
        receiptNumber: receiptNumber,
        status: status ?? this.status,
        tableNumber: tableNumber,
        customerName: customerName,
        claimedAt: claimedAt,
        deliveredAt: deliveredAt,
        createdAt: createdAt,
        orders: orders,
      );

  static String _formatTime(DateTime at) {
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return '$hh:$mm WIB';
  }

  OrderCardData toOrderCardData() => OrderCardData(
        orderId: id,
        displayNumber: receiptNumber,
        time: _formatTime(createdAt),
        tenantName: brandNames,
        tableName: 'Meja $tableNumber',
        // The API has no zone/area name on a delivery (only the zone id the
        // whole busboy session is scoped to) — left blank rather than
        // fabricated.
        location: '',
        customerName: customerName ?? '-',
        itemCount: itemCount,
        status: _orderStatusFor(status),
        deliveredDate: deliveredAt == null ? null : formatDate(deliveredAt!),
        deliveredTime: deliveredAt == null ? null : _formatTime(deliveredAt!),
      );

  OrderDetail toOrderDetail() {
    final notes = [
      for (final order in orders)
        for (final item in order.items) ?item.notes,
    ];
    return OrderDetail(
      orderId: id,
      displayNumber: receiptNumber,
      time: _formatTime(createdAt),
      tenantName: brandNames,
      tableName: 'Meja $tableNumber',
      location: '',
      customerName: customerName ?? '-',
      itemCount: itemCount,
      items: [
        for (final order in orders)
          for (final item in order.items)
            OrderLineItem(
              qty: item.quantity,
              name: item.productName,
              // The API has no per-item/order price on a delivery.
              price: '-',
            ),
      ],
      // The API has no order total on a delivery.
      total: '-',
      note: notes.isEmpty ? '-' : notes.join(', '),
    );
  }

  /// Shared by `detail-selesai` (Order tab) and `detail-riwayat` (Riwayat
  /// tab) — both screens show the same completed-delivery detail.
  CompletedOrderDetail toCompletedOrderDetail() {
    final notes = [
      for (final order in orders)
        for (final item in order.items) ?item.notes,
    ];
    final claimed = claimedAt;
    final delivered = deliveredAt;

    return CompletedOrderDetail(
      orderId: id,
      displayNumber: receiptNumber,
      tenantName: brandNames,
      // No real per-brand logo (a delivery can span brands) — the view
      // falls back to a plain placeholder tile.
      tableName: 'Meja $tableNumber',
      location: '',
      waktuAntar: claimed != null && delivered != null
          ? '${delivered.difference(claimed).inMinutes} Menit'
          : '-',
      diselesaikan: delivered == null ? '-' : _formatDateTime(delivered),
      // Only the two real timestamps the API has — the old design's middle
      // "Diantar" step had no backing data and isn't fabricated here.
      flowSteps: [
        if (claimed != null)
          DetailFlowStep(
            icon: Icons.room_service_outlined,
            label: 'Diambil',
            timestamp: _formatDateTime(claimed),
          ),
        if (delivered != null)
          DetailFlowStep(
            icon: ObraIcons.circle_check,
            label: 'Sampai Dimeja',
            timestamp: _formatDateTime(delivered),
          ),
      ],
      infoRows: [
        DetailInfoRow(label: 'Tenan', value: brandNames),
        DetailInfoRow(label: 'Meja', value: tableNumber),
        const DetailInfoRow(label: 'Zona', value: '-'),
        DetailInfoRow(label: 'Pelanggan', value: customerName ?? '-'),
        DetailInfoRow(label: 'Jumlah Item', value: '$itemCount Item'),
        DetailInfoRow(
          label: 'Catatan Tenan',
          value: notes.isEmpty ? '-' : notes.join(', '),
        ),
      ],
      lineItems: [
        for (final order in orders)
          for (final item in order.items)
            DetailLineItem(
              qty: item.quantity,
              name: item.productName,
              // The API has no per-item/order price on a delivery.
              price: '-',
            ),
      ],
      // The API has no order total on a delivery.
      total: '-',
    );
  }

  /// One row on the Riwayat (history) list.
  RiwayatEntry toRiwayatEntry() => RiwayatEntry(
        id: id,
        time: _formatTime(deliveredAt ?? createdAt),
        statusLabel: 'Selesai',
        tenantName: brandNames,
        tableName: 'Meja $tableNumber',
        location: '',
      );

  /// The calendar day this delivery is grouped under in Riwayat — the
  /// delivered date, falling back to the created date if somehow undelivered.
  DateTime get riwayatDay {
    final at = deliveredAt ?? createdAt;
    return DateTime(at.year, at.month, at.day);
  }

  static String _formatDateTime(DateTime at) {
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return '${formatDate(at)}, $hh:$mm';
  }

  /// `12 Mei 2026` — public so Riwayat's date-group headers can reuse it.
  static String formatDate(DateTime at) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${at.day} ${months[at.month - 1]} ${at.year}';
  }
}

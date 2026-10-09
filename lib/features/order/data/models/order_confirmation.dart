import 'package:flutter/foundation.dart';

/// The customer's decision on an order the kitchen could only partly fulfil —
/// sent as `decision` to `POST /v1/busboy/order-confirmations/{id}/resolve`
/// (exact upper-case strings).
enum ConfirmationDecision {
  proceed('PROCEED'),
  cancel('CANCEL');

  const ConfirmationDecision(this.wire);

  final String wire;
}

/// One line of an [OrderConfirmation] — what the kitchen could not make.
@immutable
class ConfirmationItem {
  const ConfirmationItem({
    required this.productName,
    required this.quantity,
    required this.rejectedQuantity,
    this.rejectionReason,
  });

  factory ConfirmationItem.fromJson(Map<String, dynamic> json) =>
      ConfirmationItem(
        productName: json['product_name'] as String,
        quantity: (json['quantity'] as num).toInt(),
        rejectedQuantity: (json['rejected_quantity'] as num?)?.toInt() ?? 0,
        rejectionReason: json['rejection_reason'] as String?,
      );

  final String productName;
  final int quantity;

  /// Units the kitchen rejected; 0 for a line that is fully accepted.
  final int rejectedQuantity;
  final String? rejectionReason;

  bool get isRejected => rejectedQuantity > 0;
}

/// A pending "customer must decide" task for the busboy
/// (`GET /v1/busboy/order-confirmations`, and the `order-confirmation.*`
/// realtime events, which carry the same shape).
@immutable
class OrderConfirmation {
  const OrderConfirmation({
    required this.id,
    required this.orderId,
    required this.tableNumber,
    required this.items,
    required this.createdAt,
    this.customerName,
    this.receiptNumber,
    this.brandName,
    this.busboyUserId,
    this.resolvedAt,
  });

  factory OrderConfirmation.fromJson(Map<String, dynamic> json) =>
      OrderConfirmation(
        id: json['id'] as String,
        orderId: json['order_id'] as String,
        tableNumber: json['table_number'] as String? ?? '-',
        customerName: json['customer_name'] as String?,
        receiptNumber: json['receipt_number'] as String?,
        brandName: json['brand_name'] as String?,
        busboyUserId: json['busboy_user_id'] as String?,
        resolvedAt: _parseNullable(json['resolved_at']),
        createdAt: DateTime.parse(
          (json['created_at'] as String).replaceFirst(' ', 'T'),
        ),
        items: [
          for (final item
              in (json['items'] as List? ?? const [])
                  .cast<Map<String, dynamic>>())
            ConfirmationItem.fromJson(item),
        ],
      );

  final String id;
  final String orderId;
  final String tableNumber;
  final String? customerName;
  final String? receiptNumber;
  final String? brandName;

  /// The busboy who claimed this task — null until claimed.
  final String? busboyUserId;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final List<ConfirmationItem> items;

  /// How many lines the kitchen could not (fully) make.
  int get rejectedCount => items.where((i) => i.isRejected).length;

  /// Still needs a decision, and is free or already this busboy's.
  bool isOpenFor(String? myUserId) =>
      resolvedAt == null && (busboyUserId == null || busboyUserId == myUserId);

  static DateTime? _parseNullable(Object? value) {
    if (value is! String) return null;
    return DateTime.parse(value.replaceFirst(' ', 'T'));
  }
}

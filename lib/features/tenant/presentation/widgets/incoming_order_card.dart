import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_toggle.dart';
import 'package:flutter/material.dart';

/// The tenant-side lifecycle stage of an incoming order, mapped to the three
/// "Order" sub-tabs (`menu-order-baru` / `menu-diproses` / selesai).
///
/// Drives the coloured status label and the action affordance in
/// [IncomingOrderCard]:
/// - [baru] ("Order Baru"): red `Baru` label + "Tolak" / "Terima" buttons.
/// - [diproses] ("Diproses"): amber `Diproses` label + a single full-width
///   "Siap Diambil" button.
/// - [selesai] ("Selesai"): green `Selesai` label, no action buttons.
enum IncomingOrderStatus { baru, diproses, selesai }

/// One line item of an incoming order (`Frame 2018` in the card).
@immutable
class OrderLineItem {
  const OrderLineItem({
    required this.name,
    required this.price,
    this.qty = 1,
    this.available = true,
    this.imageUrl,
  });

  /// Item name, e.g. `Paket Super Besar`.
  final String name;

  /// Pre-formatted price string, e.g. `Rp35.000`. Formatting is a caller
  /// concern — the widget never does currency math.
  final String price;

  /// Ordered quantity. Rendered as `<qty>x` in the card and `Qty : <qty>` in
  /// [OrderItemAvailabilityRow].
  final int qty;

  /// Per-item accept/reject flag (L6: an order can be rejected per item). When
  /// false the item is being rejected; the customer still receives the
  /// available items. Consumed by [OrderItemAvailabilityRow].
  final bool available;

  /// Optional thumbnail for the per-item availability row. A plain URL/string
  /// so the value object stays free of `ImageProvider`; the row falls back to
  /// a placeholder tile when null.
  final String? imageUrl;

  OrderLineItem copyWith({bool? available}) => OrderLineItem(
    name: name,
    price: price,
    qty: qty,
    available: available ?? this.available,
    imageUrl: imageUrl,
  );
}

/// Plain value object backing an [IncomingOrderCard].
///
/// Deliberately decoupled from any repository/DTO — the order data source is an
/// open question. Later items (04 Orders) map their domain model onto this.
@immutable
class IncomingOrderData {
  const IncomingOrderData({
    required this.orderId,
    required this.displayNumber,
    required this.tableName,
    required this.time,
    required this.status,
    required this.items,
    required this.total,
    this.note,
  });

  /// The real order id — what every mutation (`accept`/`reject`/`markReady`,
  /// the reject-screen route) targets. Never shown to the tenant directly;
  /// it is a raw UUID, not a human-friendly reference.
  final String orderId;

  /// Human-friendly order reference shown as `#<displayNumber>` (the
  /// receipt number, e.g. `RCP-20260826-JGP9ZT` — not [orderId], which is an
  /// unreadable UUID).
  final String displayNumber;

  /// Destination table label, e.g. `Meja A-12`.
  final String tableName;

  /// Quoted/created time, e.g. `10:36 WIB`.
  final String time;

  /// Lifecycle stage — selects the status label + action row.
  final IncomingOrderStatus status;

  /// Line items shown in the body.
  final List<OrderLineItem> items;

  /// Pre-formatted order total, e.g. `Rp40.000`.
  final String total;

  /// Free-form note. Rendered as `Catatan : <note>` (`Catatan : -` when null).
  final String? note;
}

/// Reusable incoming-order summary card (`menu-order-baru` / `menu-diproses`).
///
/// One widget covers all three sub-tabs; [IncomingOrderData.status] drives the
/// coloured label and the action affordance:
/// - [IncomingOrderStatus.baru]: [onReject] ("Tolak") + [onAccept] with an
///   overridable [acceptLabel] (defaults to `Terima`, e.g. `Terima (29s)`).
/// - [IncomingOrderStatus.diproses]: a single [onPickupReady] ("Siap Diambil").
/// - [IncomingOrderStatus.selesai]: no buttons.
///
/// Per-item accept/reject (L6) is a separate concern — render an
/// [OrderItemAvailabilityRow] per [OrderLineItem] on the rejection screen; the
/// "Tolak" button here opens that flow.
class IncomingOrderCard extends StatelessWidget {
  const IncomingOrderCard({
    required this.data,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.onPickupReady,
    this.acceptLabel,
    super.key,
  });

  /// The order to render.
  final IncomingOrderData data;

  /// Whole-card tap handler. Optional.
  final VoidCallback? onTap;

  /// "Terima" handler ([IncomingOrderStatus.baru]).
  final VoidCallback? onAccept;

  /// "Tolak" handler ([IncomingOrderStatus.baru]) — opens the per-item flow.
  final VoidCallback? onReject;

  /// "Siap Diambil" handler ([IncomingOrderStatus.diproses]).
  final VoidCallback? onPickupReady;

  /// Overrides the accept button label (defaults to `Terima`). Callers pass the
  /// live countdown, e.g. `Terima (29s)`.
  final String? acceptLabel;

  static const double _radius = 12;
  static const double _pad = 12;
  static const double _gap = 12;

  static const TextStyle _idStyle = TextStyle(
    color: AppColors.neutral900,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const TextStyle _mutedStyle = TextStyle(
    color: AppColors.neutral500,
    fontSize: 14,
    height: 1.2,
  );
  static const TextStyle _itemStyle = TextStyle(
    color: AppColors.neutral900,
    fontSize: 14,
    height: 1.2,
  );
  static const TextStyle _totalStyle = TextStyle(
    color: AppColors.neutral900,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  Color get _statusColor {
    switch (data.status) {
      case IncomingOrderStatus.baru:
        return AppColors.orderBadgeRed;
      case IncomingOrderStatus.diproses:
        return AppColors.orderBadgeAmber;
      case IncomingOrderStatus.selesai:
        return AppColors.successGreen;
    }
  }

  String get _statusLabel {
    switch (data.status) {
      case IncomingOrderStatus.baru:
        return 'Baru';
      case IncomingOrderStatus.diproses:
        return 'Diproses';
      case IncomingOrderStatus.selesai:
        return 'Selesai';
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow, // rgba(6,51,54,0.10)
            offset: Offset(0, 2),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(_pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(),
                const SizedBox(height: _gap),
                _items(),
                const SizedBox(height: _gap),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.neutral100,
                ),
                const SizedBox(height: _gap),
                _totalRow(),
                if (_hasActions) ...[
                  const SizedBox(height: _gap),
                  _actions(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasActions => data.status != IncomingOrderStatus.selesai;

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // A long receipt number can still outrun the card's width, so it
            // needs to yield space to and truncate before the fixed-width
            // status label rather than overflow past the card edge.
            Expanded(
              child: Text(
                '#${data.displayNumber}',
                style: _idStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: _gap),
            Text(
              _statusLabel,
              style: TextStyle(
                color: _statusColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(data.tableName, style: _mutedStyle),
            Text(data.time, style: _mutedStyle),
          ],
        ),
      ],
    );
  }

  Widget _items() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in data.items) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text('${item.qty}x', style: _mutedStyle),
              ),
              Expanded(child: Text(item.name, style: _itemStyle)),
              const SizedBox(width: 8),
              Text(item.price, style: _itemStyle),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Text('Catatan : ${data.note ?? '-'}', style: _mutedStyle),
      ],
    );
  }

  Widget _totalRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Total', style: _totalStyle),
        Text(data.total, style: _totalStyle),
      ],
    );
  }

  Widget _actions() {
    switch (data.status) {
      case IncomingOrderStatus.baru:
        return Row(
          children: [
            Expanded(
              child: _PillButton(
                label: 'Tolak',
                onPressed: onReject,
                outlined: true,
                color: AppColors.dangerRed,
              ),
            ),
            const SizedBox(width: _gap),
            Expanded(
              child: _PillButton(
                label: acceptLabel ?? 'Terima',
                onPressed: onAccept,
                color: AppColors.successGreen,
              ),
            ),
          ],
        );
      case IncomingOrderStatus.diproses:
        return _PillButton(
          label: 'Siap Diambil',
          onPressed: onPickupReady,
          color: AppColors.successGreen,
        );
      case IncomingOrderStatus.selesai:
        return const SizedBox.shrink();
    }
  }
}

/// Pill action button (`Frame 49`): filled by default, or outlined (white fill,
/// coloured border + label) when [outlined] is true.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.color,
    this.onPressed,
    this.outlined = false,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(100);
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: Material(
        color: outlined ? AppColors.white : color,
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: outlined ? Border.all(color: color) : null,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: outlined ? color : AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Per-item accept/reject row shown on the "Tolak Pesanan" screen
/// (`pesanan-ditolak`). Each order line gets a thumbnail, name, `Qty : N`,
/// green price, a "Tersedia" chip and an [AppToggle]: toggling it off rejects
/// that single item (L6 — partial rejection), the customer keeps the rest.
class OrderItemAvailabilityRow extends StatelessWidget {
  const OrderItemAvailabilityRow({
    required this.item,
    required this.onAvailabilityChanged,
    this.reason,
    super.key,
  });

  /// The line item; [OrderLineItem.available] drives the toggle + chip.
  final OrderLineItem item;

  /// Called with the new availability when the toggle flips.
  final ValueChanged<bool> onAvailabilityChanged;

  /// Rejection reason for a rejected item (`konfirmasi-pesanan`). Only rendered
  /// when the item is unavailable; adds a hairline + `Alasan : <reason>` line
  /// below the row. Null on the initial `pesanan-ditolak` screen.
  final String? reason;

  static const double _radius = 12;
  static const double _thumb = 56;

  bool get _rejected => !item.available;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _rejected ? AppColors.rejectedItemFill : AppColors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: _rejected
            ? Border.all(color: AppColors.rejectedItemBorder)
            : null,
        boxShadow: _rejected
            ? null
            : const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  offset: Offset(0, 2),
                  blurRadius: 16,
                ),
              ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _thumbnail(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: AppColors.neutral900,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Qty : ${item.qty}',
                      style: const TextStyle(
                        color: AppColors.neutral500,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.price,
                      style: const TextStyle(
                        color: AppColors.successGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusChip(),
              const SizedBox(width: 8),
              AppToggle(
                value: item.available,
                semanticLabel: 'Ketersediaan ${item.name}',
                onChanged: onAvailabilityChanged,
                offColor: AppColors.dangerRed,
              ),
            ],
          ),
          if (_rejected && reason != null) ...[
            const SizedBox(height: 12),
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.rejectedItemBorder,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Alasan : ',
                  style: TextStyle(
                    color: AppColors.neutral900,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                Expanded(
                  child: Text(
                    reason!,
                    style: const TextStyle(
                      color: AppColors.neutral900,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// The "Tersedia" (green) / "Tidak Tersedia" (red) availability chip.
  Widget _statusChip() {
    if (item.available) return _availabilityChip();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.dangerChipTint,
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Text(
        'Tidak Tersedia',
        style: TextStyle(
          color: AppColors.dangerRed,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _thumbnail() {
    // TODO(open-question): imageUrl is a plain string; wire a real image
    // loader (cached_network_image / asset) once the menu media source exists.
    return Container(
      width: _thumb,
      height: _thumb,
      decoration: BoxDecoration(
        color: AppColors.neutralTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.neutral300,
      ),
    );
  }

  Widget _availabilityChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successTint,
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Text(
        'Tersedia',
        style: TextStyle(
          color: AppColors.success700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}

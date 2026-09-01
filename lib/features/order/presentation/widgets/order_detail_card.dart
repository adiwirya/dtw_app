import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/order/data/models/order_models.dart';
import 'package:flutter/material.dart';
import 'package:obra_icons/obra_icons.dart';

/// The order identity card at the top of the `menu-order-baru-2` ("Detail
/// Pesanan") screen (`Frame 2434`): the order id + time header over three
/// divider-separated rows — Dari Tenant, Ke Meja, and Pelanggan (with a
/// call-out phone button).
///
/// Distinct from the shared `OrderCard` (list item) — this variant uses full
/// hairline dividers between rows and a trailing phone-call affordance, so it
/// is a purpose-built detail widget.
class OrderDetailCard extends StatelessWidget {
  const OrderDetailCard({required this.detail, this.onCall, super.key});

  final OrderDetail detail;

  /// Tap handler for the "phone-outgoing" call button on the Pelanggan row.
  final VoidCallback? onCall;

  static const double _tile = 30;
  static const double _tileRadius = 8;
  static const double _icon = 16;

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
  static const TextStyle _labelStyle = TextStyle(
    color: AppColors.neutral500,
    fontSize: 12,
    height: 1.2,
  );
  static const TextStyle _valueStyle = TextStyle(
    color: AppColors.neutral900,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          const SizedBox(height: 12),
          _tenantRow(),
          _divider(),
          _tableRow(),
          _divider(),
          _customerRow(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('#${detail.displayNumber}', style: _idStyle),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              ObraIcons.clock_3,
              size: _icon,
              color: AppColors.neutral500,
            ),
            const SizedBox(width: 8),
            Text(detail.time, style: _mutedStyle),
          ],
        ),
      ],
    );
  }

  Widget _tenantRow() {
    return _infoRow(
      icon: ObraIcons.store,
      tileBg: AppColors.orderTileTenantBg,
      tileIcon: AppColors.orderTileTenantIcon,
      label: 'Dari Tenant',
      value: Text(detail.tenantName, style: _valueStyle),
    );
  }

  Widget _tableRow() {
    return _infoRow(
      icon: ObraIcons.chair,
      tileBg: AppColors.successTint,
      tileIcon: AppColors.successGreen,
      label: 'Ke Meja',
      value: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(detail.tableName, style: _valueStyle)),
          _dot(),
          Flexible(child: Text(detail.location, style: _valueStyle)),
        ],
      ),
    );
  }

  Widget _customerRow() {
    return Row(
      children: [
        Expanded(
          child: _infoRow(
            icon: ObraIcons.user,
            tileBg: AppColors.orderTileCustomerBg,
            tileIcon: AppColors.orderTileCustomerIcon,
            label: 'Pelanggan',
            value: Text(detail.customerName, style: _valueStyle),
          ),
        ),
        const SizedBox(width: 12),
        _CallButton(onTap: onCall),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color tileBg,
    required Color tileIcon,
    required String label,
    required Widget value,
  }) {
    return Row(
      children: [
        _iconTile(icon, tileBg, tileIcon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: _labelStyle),
              const SizedBox(height: 2),
              value,
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconTile(IconData icon, Color bg, Color iconColor) {
    return Container(
      width: _tile,
      height: _tile,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_tileRadius),
      ),
      child: Center(child: Icon(icon, size: _icon, color: iconColor)),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, thickness: 1, color: AppColors.neutral100),
    );
  }

  Widget _dot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 4,
        height: 4,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.neutral500,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    return Material(
      color: AppColors.neutralTint,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Center(
            // TODO(open-question): no obra "phone-outgoing" glyph; using the
            // base phone icon until the exact SVG is bundled.
            child: Icon(
              ObraIcons.phone,
              size: 18,
              color: AppColors.neutral500,
            ),
          ),
        ),
      ),
    );
  }
}

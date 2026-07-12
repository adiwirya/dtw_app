import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The lifecycle stage of an order, mapped to the three Menu Order sub-tabs.
///
/// Drives every visual difference in [OrderCard]:
/// - [baru] ("Ambil"): tenant + table rows, a customer/item footer and a
///   "Detail" affordance. No action button.
/// - [antar] ("Antar"): same as [baru] plus a full-width primary action
///   button ("Sampai dimeja" by default).
/// - [selesai] ("Selesai"): adds a "Pelanggan" row, and swaps the footer for a
///   delivered-at ("Diantar pada") summary with an item count. No "Detail",
///   no action button.
enum OrderStatus { baru, antar, selesai }

/// Plain value object backing an [OrderCard].
///
/// Deliberately decoupled from any repository/DTO — the real data source is an
/// open question (see work item L3). Later items (07 Menu Order list, 10
/// detail) can map their domain model onto this or construct it directly.
///
/// Open question: this should be replaced with the mapped domain entity once
/// the order data source / API contract is decided.
@immutable
class OrderCardData {
  const OrderCardData({
    required this.orderId,
    required this.time,
    required this.tenantName,
    required this.tableName,
    required this.location,
    required this.customerName,
    required this.itemCount,
    required this.status,
    this.deliveredDate,
    this.deliveredTime,
  });

  /// Order number without the leading '#'. Rendered as `#<orderId>`.
  final String orderId;

  /// Created/quoted time, e.g. `10:31 WIB`. Rendered verbatim beside the clock.
  final String time;

  /// Source tenant name, e.g. `KFC Fried Chicken` ("Dari Tenant" row).
  final String tenantName;

  /// Destination table label, e.g. `Meja A-12` ("Ke Meja" row).
  final String tableName;

  /// Destination area/zone, e.g. `Downtown` (shown after the table name).
  final String location;

  /// Customer name. Shown in the footer ([OrderStatus.baru]/
  /// [OrderStatus.antar]) or the "Pelanggan" row ([OrderStatus.selesai]).
  final String customerName;

  /// Number of line items. Rendered as `<itemCount> Item`.
  final int itemCount;

  /// Order lifecycle stage. Selects the card layout — see [OrderStatus].
  final OrderStatus status;

  /// Delivered-on date for [OrderStatus.selesai], e.g. `12 Mei 2024`.
  /// Ignored for other statuses.
  final String? deliveredDate;

  /// Delivered-at time for [OrderStatus.selesai], e.g. `10:45 WIB`.
  /// Ignored for other statuses.
  final String? deliveredTime;
}

/// Reusable order list-item rendered across the three Menu Order sub-tabs
/// (Baru / Antar / Selesai) and referenced by the history/detail screens.
///
/// One widget covers all three frames; [OrderCardData.status] drives the badge
/// rows, footer and action affordances. Pass [onTap] for the whole-card tap
/// (open detail), [onDetailTap] for the explicit "Detail" affordance (falls
/// back to [onTap] when null), and [onPrimaryAction] for the "Antar" action
/// button.
///
/// Cached design values (`menu-order-*`): white surface, 12px radius, drop
/// shadow `0 2 16 rgba(6,51,54,0.10)`, 12px padding, 12px section gaps, 30x30
/// icon tiles (radius 8, 16px glyph).
class OrderCard extends StatelessWidget {
  const OrderCard({
    required this.data,
    this.onTap,
    this.onDetailTap,
    this.onPrimaryAction,
    this.primaryActionLabel,
    super.key,
  });

  /// The order to render.
  final OrderCardData data;

  /// Whole-card tap handler (typically opens the order detail). Optional.
  final VoidCallback? onTap;

  /// Tap handler for the "Detail" affordance ([OrderStatus.baru]/
  /// [OrderStatus.antar]). Falls back to [onTap] when null.
  final VoidCallback? onDetailTap;

  /// Tap handler for the primary action button ([OrderStatus.antar]).
  final VoidCallback? onPrimaryAction;

  /// Overrides the primary action button label. Defaults to `Sampai dimeja`.
  final String? primaryActionLabel;

  // --- Cached design tokens (menu-order-* frames) -------------------------

  static const double _radius = 12;
  static const double _pad = 12;
  static const double _gap = 12;
  static const double _tile = 30;
  static const double _tileRadius = 8;
  static const double _icon = 16;

  // TODO(open-question): the "Dari Tenant" (blue) and "Pelanggan" (purple)
  // icon-tile colors are not in tokens.json; these are eyeballed from the
  // references. Replace with real tokens if/when they are added.
  static const Color _tenantTileBg = Color(0xFFEAF1FB);
  static const Color _tenantTileIcon = Color(0xFF3B7DD8);
  static const Color _customerTileBg = Color(0xFFF4ECFB);
  static const Color _customerTileIcon = Color(0xFF9B51E0);

  // Text styles (Open Sans in the cache; not bundled yet — default family).
  // TODO(open-question): swap to Open Sans once the font is added.
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
  static const TextStyle _customerStyle = TextStyle(
    color: AppColors.neutral900,
    fontSize: 14,
    height: 1.2,
  );
  static const TextStyle _detailStyle = TextStyle(
    color: AppColors.successGreen,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const TextStyle _actionStyle = TextStyle(
    color: AppColors.white,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  bool get _showsCustomerFooter =>
      data.status == OrderStatus.baru || data.status == OrderStatus.antar;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A063336), // rgba(6,51,54,0.10)
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
                _infoRows(),
                const SizedBox(height: _gap),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.neutral100,
                ),
                const SizedBox(height: _gap),
                _footerSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('#${data.orderId}', style: _idStyle),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.access_time,
              size: _icon,
              color: AppColors.neutral500,
            ),
            const SizedBox(width: 8),
            Text(data.time, style: _mutedStyle),
          ],
        ),
      ],
    );
  }

  Widget _infoRows() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _infoRow(
          // TODO(open-question): SVG icon-store wanted; using the Material
          // storefront glyph until flutter_svg is a dependency.
          icon: Icons.storefront_outlined,
          tileBg: _tenantTileBg,
          tileIcon: _tenantTileIcon,
          label: 'Dari Tenant',
          value: Text(data.tenantName, style: _valueStyle),
        ),
        const SizedBox(height: _gap),
        _infoRow(
          icon: Icons.chair_outlined,
          tileBg: AppColors.successTint,
          tileIcon: AppColors.successGreen,
          label: 'Ke Meja',
          value: _dotSeparated(
            Text(data.tableName, style: _valueStyle),
            Text(data.location, style: _valueStyle),
          ),
        ),
        if (data.status == OrderStatus.selesai) ...[
          const SizedBox(height: _gap),
          _infoRow(
            icon: Icons.person_outline,
            tileBg: _customerTileBg,
            tileIcon: _customerTileIcon,
            label: 'Pelanggan',
            value: Text(data.customerName, style: _valueStyle),
          ),
        ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconTile(icon, tileBg, tileIcon),
        const SizedBox(width: _gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: _labelStyle),
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

  Widget _footerSection() {
    switch (data.status) {
      case OrderStatus.baru:
        return _customerFooter();
      case OrderStatus.antar:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _customerFooter(),
            const SizedBox(height: 16),
            _actionButton(),
          ],
        );
      case OrderStatus.selesai:
        return _deliveredFooter();
    }
  }

  Widget _customerFooter() {
    assert(_showsCustomerFooter, 'customer footer is baru/antar only');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.person_outline,
                  size: _icon, color: AppColors.neutral500),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  data.customerName,
                  style: _customerStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _dot(),
              Text('${data.itemCount} Item', style: _mutedStyle),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onDetailTap ?? onTap,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Detail', style: _detailStyle),
              SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: _icon,
                color: AppColors.successGreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _deliveredFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Diantar pada', style: _labelStyle),
              const SizedBox(height: 4),
              _dotSeparated(
                Text(data.deliveredDate ?? '', style: _valueStyle),
                Text(data.deliveredTime ?? '', style: _valueStyle),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('${data.itemCount} Item', style: _mutedStyle),
      ],
    );
  }

  Widget _actionButton() {
    final radius = BorderRadius.circular(_tileRadius);
    return SizedBox(
      width: double.infinity,
      height: 32,
      child: Material(
        color: AppColors.successGreen,
        borderRadius: radius,
        child: InkWell(
          onTap: onPrimaryAction,
          borderRadius: radius,
          child: Center(
            child: Text(
              primaryActionLabel ?? 'Sampai dimeja',
              style: _actionStyle,
            ),
          ),
        ),
      ),
    );
  }

  /// `<a> • <b>` with an 8px gap either side of the neutral dot.
  Widget _dotSeparated(Widget a, Widget b) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Flexible(child: a), _dot(), Flexible(child: b)],
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

import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_toggle.dart';
import 'package:flutter/material.dart';

/// Plain value object backing a [MenuItemCard] (`menu-saya` list row).
///
/// Decoupled from any DTO — the menu data source is an open question. Item 06
/// (Menu management) maps its domain model onto this.
@immutable
class MenuItemData {
  const MenuItemData({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice,
    this.popular = false,
    this.stockLabel = 'Stok : Tersedia',
    this.active = true,
    this.imageUrl,
  });

  /// The backing product id (`Product.id`) — needed to target the
  /// per-branch availability toggle at the right product.
  final String id;

  /// Menu name, e.g. `Paket Super Besar`.
  final String name;

  /// Pre-formatted (discounted) price, e.g. `Rp35.000`. No currency math here.
  final String price;

  /// Pre-formatted pre-discount price, e.g. `Rp45.000`. When non-null it is
  /// rendered struck-through before [price] to convey a discount (L6). Null =
  /// no discount.
  final String? originalPrice;

  /// PIN / "Populer" label (L6 — replaces the old "best seller" flag). When
  /// true a "Populer" badge is shown beside the name.
  final bool popular;

  /// Stock caption under the price, e.g. `Stok : Tersedia`.
  final String stockLabel;

  /// Whether the menu is active/available. Drives the trailing chip + toggle.
  final bool active;

  /// Optional thumbnail URL. Placeholder tile shown when null.
  final String? imageUrl;

  MenuItemData copyWith({bool? active}) => MenuItemData(
        id: id,
        name: name,
        price: price,
        originalPrice: originalPrice,
        popular: popular,
        stockLabel: stockLabel,
        active: active ?? this.active,
        imageUrl: imageUrl,
      );
}

/// Reusable menu list-item card (`menu-saya` / management list).
///
/// Layout: thumbnail, name (+ optional "Populer" badge), price (with optional
/// struck-through [MenuItemData.originalPrice] discount), stock caption, and a
/// trailing state chip + [AppToggle]. Pass [onActiveChanged] to react to the
/// toggle and [onTap] for the whole-card tap (open the editor).
class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    required this.data,
    this.onActiveChanged,
    this.onTap,
    super.key,
  });

  /// The menu to render.
  final MenuItemData data;

  /// Called with the new active state when the toggle flips. Null hides the
  /// toggle interaction (renders disabled).
  final ValueChanged<bool>? onActiveChanged;

  /// Whole-card tap handler (open the editor). Optional.
  final VoidCallback? onTap;

  static const double _radius = 12;
  static const double _thumb = 64;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
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
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _thumbnail(),
                const SizedBox(width: 12),
                Expanded(child: _body()),
                const SizedBox(width: 8),
                _trailing(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbnail() {
    // TODO(open-question): imageUrl is a plain string placeholder; wire a real
    // image loader once the menu media source exists.
    return Container(
      width: _thumb,
      height: _thumb,
      decoration: BoxDecoration(
        color: AppColors.neutralTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, color: AppColors.neutral300),
    );
  }

  Widget _body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                data.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            if (data.popular) ...[
              const SizedBox(width: 8),
              _popularBadge(),
            ],
          ],
        ),
        const SizedBox(height: 2),
        _priceRow(),
        const SizedBox(height: 4),
        Text(
          data.stockLabel,
          style: const TextStyle(
            color: AppColors.successGreen,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _priceRow() {
    final price = Text(
      data.price,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.neutral500,
        fontSize: 14,
        height: 1.2,
      ),
    );
    if (data.originalPrice == null) return price;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            data.originalPrice!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.neutral300,
              fontSize: 12,
              height: 1.2,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(child: price),
      ],
    );
  }

  Widget _popularBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.successTint,
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Text(
        'Populer',
        style: TextStyle(
          color: AppColors.success700,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _trailing() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: data.active ? AppColors.successTint : AppColors.neutralTint,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            data.active ? 'Aktif' : 'Nonaktif',
            style: TextStyle(
              color: data.active ? AppColors.success700 : AppColors.neutral500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        AppToggle(
          value: data.active,
          semanticLabel: 'Status ${data.name}',
          onChanged: onActiveChanged,
        ),
      ],
    );
  }
}

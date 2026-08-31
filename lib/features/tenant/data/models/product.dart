import 'package:dtw_app/core/utils/currency.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_item_card.dart';
import 'package:flutter/foundation.dart';

/// A brand's product ("Menu" in the tenant UI), as returned by
/// `GET /v1/products` (confirmed live — see `docs/api-reference.md`).
///
/// **Known gap:** the endpoint has no stock/discount/tag-display fields the
/// `menu-saya` UI expects — [toMenuItemData] leaves those at their
/// [MenuItemData] defaults rather than fabricate values.
@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.totalPrice,
    required this.isActive,
    this.categoryId,
    this.description,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      totalPrice: (json['total_price'] as num).round(),
      // `PUT /v1/products/{id}` takes `is_active`, so an edit has to send the
      // product's current value back rather than assume `true` and silently
      // reactivate something the tenant had deactivated.
      isActive: json['is_active'] as bool? ?? true,
      categoryId: json['category_id'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  final String id;
  final String name;

  /// The product's active flag — this is what the Menu Saya toggle controls,
  /// via `PUT /v1/products/{id}`'s `is_active`. There is no separate
  /// per-branch availability endpoint on the live API.
  final bool isActive;

  /// The product's category. Needed to seed the edit form's `Kategori`
  /// dropdown; null on responses that omit it.
  final String? categoryId;

  /// Free-text note, shown in the form's `Catatan` field.
  final String? description;

  /// Tax-inclusive price the customer pays (`dpp_price` + `pb1_price`,
  /// already summed server-side).
  final int totalPrice;
  final String? imageUrl;

  MenuItemData toMenuItemData() => MenuItemData(
        id: id,
        name: name,
        price: formatRupiah(totalPrice),
        active: isActive,
        imageUrl: imageUrl,
      );
}

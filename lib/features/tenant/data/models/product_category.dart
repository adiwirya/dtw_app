import 'package:flutter/foundation.dart';

/// A brand's product category, as returned by `GET /v1/product-categories`
/// (see `docs/api-reference.md`). Backs the `Kategori` dropdown on the
/// add-menu form, whose `category_id` is required by `POST /v1/products`.
///
/// Only the two fields the form actually needs are modelled. The endpoint also
/// returns `parent_category_id` / `sequence_order` / `is_active`; nested
/// categories and ordering are not part of the form yet.
@immutable
class ProductCategory {
  const ProductCategory({required this.id, required this.name});

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  final String id;
  final String name;
}

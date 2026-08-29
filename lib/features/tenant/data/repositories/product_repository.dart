import 'package:dio/dio.dart';
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/network/dio_provider.dart';
import 'package:dtw_app/features/tenant/data/models/modifier_group.dart';
import 'package:dtw_app/features/tenant/data/models/product.dart';
import 'package:dtw_app/features/tenant/data/models/product_category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'product_repository.g.dart';

class ProductRepository {
  const ProductRepository({required this._dio});

  final Dio _dio;

  Future<List<Product>> fetchProducts({required String brandId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/products',
        queryParameters: {'brand_id': brandId},
      );
      final data = response.data!['data'] as List;
      return data
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// The brand's product categories (`GET /v1/product-categories`), for the
  /// add-menu form's required `category_id`.
  ///
  // TODO(open-question): the spec documents no query params for this list.
  // `brand_id` is passed by analogy with `/v1/products` and
  // `/v1/modifier-groups`, which both filter that way — confirm live that it
  // is honored rather than ignored (an ignored filter would offer another
  // brand's categories).
  Future<List<ProductCategory>> fetchCategories({
    required String brandId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/product-categories',
        queryParameters: {'brand_id': brandId},
      );
      final data = response.data!['data'] as List;
      return data
          .map((json) => ProductCategory.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// Creates a product (`POST /v1/products`) and returns it as the API echoes
  /// it back — the response carries the server-computed `total_price`, which
  /// is what the Menu Saya list renders.
  ///
  /// [price] is sent verbatim as the endpoint's `price` field, which is
  /// **tax-inclusive** — the amount the customer pays, matching the
  /// [Product.totalPrice] the response echoes back. The backend derives
  /// `dpp_price` and `pb1_price` from it (the live sample splits total 19900
  /// into dpp 17927.93 + 11% pb1 1972.07).
  ///
  /// So the form round-trips one number: it seeds from `total_price` and sends
  /// that same number back. Do NOT "correct" this by dividing out the 11% —
  /// that would silently cut every edited price, and
  /// `product_repository_test.dart` locks the round-trip against exactly that.
  Future<Product> createProduct({
    required String brandId,
    required String categoryId,
    required String name,
    required int price,
    String? description,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/products',
        data: {
          'brand_id': brandId,
          'category_id': categoryId,
          'name': name,
          'price': price,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
      return Product.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// One product with its editable fields (`GET /v1/products/{id}`).
  Future<Product> fetchProduct(String productId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/products/$productId',
      );
      return Product.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// Updates a product (`PUT /v1/products/{id}`).
  ///
  /// [isActive] is sent as-is rather than hardcoded: it is the product's
  /// brand-level flag, and defaulting it to true would silently reactivate a
  /// product the tenant had turned off.
  ///
  /// [price] is tax-inclusive, as in [createProduct].
  Future<Product> updateProduct(
    String productId, {
    required String categoryId,
    required String name,
    required int price,
    required bool isActive,
    String? description,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/v1/products/$productId',
        data: {
          'category_id': categoryId,
          'name': name,
          'price': price,
          'is_active': isActive,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
      return Product.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// The modifier groups (variants) currently attached to [productId]
  /// (`GET /v1/products/{productId}/modifier-groups`), so an edit form can
  /// show what is already attached instead of implying nothing is.
  Future<List<ModifierGroup>> fetchProductModifierGroups(
    String productId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/products/$productId/modifier-groups',
      );
      final data = response.data!['data'] as List;
      return data
          .map((json) => ModifierGroup.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// Replaces the set of modifier groups (variants) attached to [productId]
  /// (`POST /v1/products/{productId}/modifier-groups/sync`).
  ///
  /// A full replace, not an append: passing an empty list detaches every
  /// variant from the product.
  Future<void> syncModifierGroups(
    String productId, {
    required List<String> modifierGroupIds,
  }) async {
    try {
      await _dio.post<void>(
        '/v1/products/$productId/modifier-groups/sync',
        data: {'modifier_group_ids': modifierGroupIds},
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// Per-branch availability (confirmed live shape: `[{id, name, total_price,
  /// category_id, category_name, is_available}]`) — keyed here by product id
  /// since that's all callers need to merge onto [Product.toMenuItemData].
  Future<Map<String, bool>> fetchAvailability({
    required String branchId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/tenant-branches/$branchId/product-availability',
      );
      final data = response.data!['data'] as List;
      return {
        for (final item in data.cast<Map<String, dynamic>>())
          item['id'] as String: item['is_available'] as bool,
      };
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> updateAvailability(
    String productId, {
    required String branchId,
    required bool isAvailable,
  }) async {
    try {
      await _dio.patch<void>(
        '/v1/tenant-branches/$branchId/product-availability/$productId',
        data: {'is_available': isAvailable},
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}

@riverpod
ProductRepository productRepository(Ref ref) =>
    ProductRepository(dio: ref.watch(dioProvider));

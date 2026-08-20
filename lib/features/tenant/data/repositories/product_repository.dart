import 'package:dio/dio.dart';
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/network/dio_provider.dart';
import 'package:dtw_app/features/tenant/data/models/product.dart';
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

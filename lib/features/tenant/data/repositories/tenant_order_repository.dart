import 'package:dio/dio.dart';
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/network/dio_provider.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tenant_order_repository.g.dart';

class TenantOrderRepository {
  TenantOrderRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<TenantOrder>> fetchOrders({required String branchId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/orders',
        queryParameters: {'branch_id': branchId},
      );
      final data = response.data!['data'] as List;
      return data
          .map((json) => TenantOrder.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> updateStatus(
    String orderId, {
    required TenantOrderStatus status,
    String? reason,
  }) async {
    try {
      await _dio.patch<void>(
        '/v1/orders/$orderId/status',
        data: {
          'order_status': tenantOrderStatusToWire(status),
          if (reason != null) 'reason': reason,
        },
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<List<TenantOrder>> fetchMissedEvents({
    required String branchId,
    required int afterId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/broadcast/replay',
        queryParameters: {'branch_id': branchId, 'after_id': afterId},
      );
      final data = response.data!['data'] as List;
      return data
          .map((json) => TenantOrder.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}

@riverpod
TenantOrderRepository tenantOrderRepository(Ref ref) =>
    TenantOrderRepository(dio: ref.watch(dioProvider));

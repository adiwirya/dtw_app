import 'package:dio/dio.dart';
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/network/dio_provider.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tenant_order_repository.g.dart';

/// One rejected line of `POST /v1/orders/{id}/process`: [quantity] units of
/// item [id] are refused (the rest of the line stays accepted), for [reason].
class RejectedItem {
  const RejectedItem({
    required this.id,
    required this.reason,
    required this.quantity,
  });

  final String id;
  final String reason;
  final int quantity;

  Map<String, Object> toJson() => {
    'id': id,
    'reason': reason,
    'quantity': quantity,
  };
}

class TenantOrderRepository {
  const TenantOrderRepository({required this._dio});

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

  /// Moves an order already past PENDING to [status] (only `markReady` —
  /// PREPARING → READY — calls this; the PENDING accept/reject decision goes
  /// through [processOrder] instead).
  Future<void> updateStatus(
    String orderId, {
    required TenantOrderStatus status,
  }) async {
    try {
      await _dio.patch<void>(
        '/v1/orders/$orderId/status',
        data: {'order_status': tenantOrderStatusToWire(status)},
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// The tenant's item-level decision on a PENDING order. The backend derives
  /// the resulting status from [rejectedItems]: empty → every item
  /// accepted, order → PREPARING; some → the rest accepted, order →
  /// AWAITING_CONFIRMATION (customer decides via a busboy); all → order →
  /// CANCELLED. 400s if the order is no longer PENDING.
  Future<void> processOrder(
    String orderId, {
    required List<RejectedItem> rejectedItems,
  }) async {
    try {
      await _dio.post<void>(
        '/v1/orders/$orderId/process',
        data: {
          'rejected_items': [for (final i in rejectedItems) i.toJson()],
        },
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// Completes a self-pickup order once the tenant confirms the customer's
  /// pickup code (`api-tenant-busboy-guide.md` §3). A wrong code returns 422
  /// with a `pickup_code` field error (`mapDioError` surfaces its message,
  /// e.g. "Kode pickup tidak sesuai.", verbatim via [ApiException.message]).
  Future<void> completePickup(
    String orderId, {
    required String pickupCode,
  }) async {
    try {
      await _dio.post<void>(
        '/v1/orders/$orderId/complete-pickup',
        data: {'pickup_code': pickupCode},
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
          // Each replay item is `{id, event, payload, created_at}` — the
          // order lives under `payload`, in the same order/order_group-
          // wrapped shape as a live `order.created` event, not flat like
          // `GET /v1/orders`.
          .map(
            (json) => TenantOrder.fromBroadcastPayload(
              (json as Map<String, dynamic>)['payload'] as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}

@riverpod
TenantOrderRepository tenantOrderRepository(Ref ref) =>
    TenantOrderRepository(dio: ref.watch(dioProvider));

import 'package:dio/dio.dart';
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/network/dio_provider.dart';
import 'package:dtw_app/features/order/data/models/delivery.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'busboy_delivery_repository.g.dart';

class BusboyDeliveryRepository {
  const BusboyDeliveryRepository({required this._dio});

  final Dio _dio;

  Future<List<Delivery>> fetchDeliveries({DeliveryStatus? status}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/busboy/deliveries',
        queryParameters: {
          if (status != null) 'status': _statusToWire(status),
        },
      );
      final data = response.data!['data'] as List;
      return data
          .map((json) => Delivery.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> claim(String deliveryId) async {
    try {
      await _dio.post<void>('/v1/busboy/deliveries/$deliveryId/claim');
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> complete(String deliveryId) async {
    try {
      await _dio.post<void>('/v1/busboy/deliveries/$deliveryId/complete');
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  String _statusToWire(DeliveryStatus status) => switch (status) {
        DeliveryStatus.pendingPickup => 'PENDING_PICKUP',
        DeliveryStatus.claimed => 'CLAIMED',
        DeliveryStatus.delivered => 'DELIVERED',
      };
}

@riverpod
BusboyDeliveryRepository busboyDeliveryRepository(Ref ref) =>
    BusboyDeliveryRepository(dio: ref.watch(dioProvider));

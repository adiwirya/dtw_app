import 'package:dio/dio.dart';
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/network/dio_provider.dart';
import 'package:dtw_app/features/order/data/models/order_confirmation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'busboy_confirmation_repository.g.dart';

/// `GET/POST /v1/busboy/order-confirmations…` — the tasks where the kitchen
/// rejected some items and the customer must choose PROCEED or CANCEL.
class BusboyConfirmationRepository {
  const BusboyConfirmationRepository({required this._dio});

  final Dio _dio;

  Future<List<OrderConfirmation>> fetchConfirmations() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/busboy/order-confirmations',
      );
      final data = response.data!['data'] as List;
      return data
          .map((j) => OrderConfirmation.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 409 when another busboy claimed it first.
  Future<OrderConfirmation> claim(String confirmationId) =>
      _post('/v1/busboy/order-confirmations/$confirmationId/claim');

  Future<OrderConfirmation> resolve(
    String confirmationId,
    ConfirmationDecision decision,
  ) => _post(
    '/v1/busboy/order-confirmations/$confirmationId/resolve',
    data: {'decision': decision.wire},
  );

  Future<OrderConfirmation> _post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      return OrderConfirmation.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// `mapDioError` turns every non-401/422 status into a generic message, which
  /// would hide the one failure a busboy can actually hit here: another busboy
  /// claimed the task first (409), or it was already decided (422).
  ApiException _mapError(DioException error) =>
      switch (error.response?.statusCode) {
        409 => ApiException(message: 'Tugas ini sudah diambil busboy lain.'),
        422 => ApiException(
          message: 'Konfirmasi tidak ditemukan atau sudah diselesaikan.',
        ),
        _ => mapDioError(error),
      };
}

@riverpod
BusboyConfirmationRepository busboyConfirmationRepository(Ref ref) =>
    BusboyConfirmationRepository(dio: ref.watch(dioProvider));

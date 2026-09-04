import 'package:dio/dio.dart';
import 'package:dtw_app/core/realtime/busboy_realtime_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/order/data/repositories/busboy_delivery_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'canned_dio.dart';
import 'fake_busboy_realtime_service.dart';
import 'fake_local_storage.dart';

/// The zone id every busboy-board test is scoped to.
const String testZoneId = 'zone-1';

/// One item in the busboy `GET /api/v1/busboy/deliveries` item shape.
/// [id] is the delivery's real identifier — claim/complete target and board
/// lookup key. There is no `receipt_number` at this level (confirmed live):
/// it lives per-order instead — see [deliveryOrderJson].
Map<String, dynamic> deliveryJson({
  required String id,
  required String status,
  String tableNumber = 'A12',
  String? customerName = 'Budi Santoso',
  String? claimedAt,
  String? deliveredAt,
  String createdAt = '2026-08-27 10:31:00',
  List<Map<String, dynamic>> orders = const [],
}) => {
  'id': id,
  'status': status,
  'table_number': tableNumber,
  'customer_name': customerName,
  'claimed_at': claimedAt,
  'delivered_at': deliveredAt,
  'created_at': createdAt,
  'orders': orders,
};

/// One order within a [deliveryJson]'s `orders` list. [receiptNumber]
/// defaults off [orderId] — give it explicitly in a test that cares about
/// the receipt number's actual value.
Map<String, dynamic> deliveryOrderJson({
  required String orderId,
  String brandName = 'Janji Jiwa',
  String? receiptNumber,
  List<Map<String, dynamic>> items = const [],
}) => {
  'order_id': orderId,
  'brand_name': brandName,
  'receipt_number': receiptNumber ?? 'RCP-$orderId',
  'items': items,
};

/// One item within a [deliveryOrderJson]'s `items` list.
Map<String, dynamic> deliveryItemJson({
  required String productName,
  int quantity = 1,
  int subtotal = 15000,
  String? notes,
}) => {
  'product_name': productName,
  'quantity': quantity,
  'subtotal': subtotal,
  'notes': notes,
};

/// Wraps [data] in the CMS success envelope every endpoint returns.
Map<String, dynamic> busboyEnvelope(Object? data) => {
  'meta': {
    'success': true,
    'message': 'Success',
    'code': 200,
    'trace_id': 'abc',
  },
  'data': data,
};

/// A [Dio] whose every request answers with [deliveries] in the list
/// envelope.
Dio cannedDeliveryListDio(List<Map<String, dynamic>> deliveries) =>
    cannedDio(200, busboyEnvelope(deliveries));

/// A zone-scoped [FakeLocalStorage], as `OrderBoardNotifier` requires.
FakeLocalStorage zoneScopedStorage() =>
    FakeLocalStorage()..values[busboyZoneIdStorageKey] = testZoneId;

/// Provider overrides standing up a real `OrderBoardNotifier` over [dio]: a
/// zone-scoped local storage, a real repository, and a fake realtime service
/// (a widget test has no socket, and an un-faked one hangs the board's
/// initial fetch on an unmocked platform channel).
List<Override> busboyBoardOverrides({
  required Dio dio,
  FakeLocalStorage? storage,
  BusboyRealtimeService? realtime,
}) => [
  localStorageProvider.overrideWithValue(storage ?? zoneScopedStorage()),
  busboyDeliveryRepositoryProvider.overrideWithValue(
    BusboyDeliveryRepository(dio: dio),
  ),
  busboyRealtimeServiceProvider.overrideWithValue(
    realtime ?? FakeBusboyRealtimeService(),
  ),
];

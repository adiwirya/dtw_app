import 'package:dio/dio.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_branch_repository.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_order_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'canned_dio.dart';
import 'fake_local_storage.dart';
import 'fake_tenant_realtime_service.dart';

/// The branch id every tenant-board test is scoped to.
///
/// `TenantOrderBoard.build` throws without a stored branch id, so *every*
/// test that renders a tenant order screen has to seed one — which is why
/// this, the canned order shape and the provider overrides all live here
/// instead of being retyped in each test file.
const String testBranchId = 'branch-1';

/// One order in the live `GET /v1/orders` / `order.created` item shape.
///
/// Defaults match the confirmed live payload (see
/// `test/features/tenant/data/models/tenant_order_test.dart`); override only
/// what a given test actually asserts on.
Map<String, dynamic> tenantOrderJson({
  required String id,
  required String status,
  int grandTotal = 21000,
  String? receiptNumber,
  String createdAt = '2026-08-07 09:24:08',
  int? broadcastEventId,
  List<Map<String, dynamic>> items = const [],
}) => {
  'id': id,
  'order_group_id': 'group-$id',
  'branch_id': testBranchId,
  'receipt_number': receiptNumber ?? 'RCP-$id',
  'grand_total': grandTotal,
  'order_status': status,
  'created_at': createdAt,
  'updated_at': createdAt,
  'items': items,
  'broadcast_event_id': ?broadcastEventId,
};

/// One order item in the live item shape — just enough for
/// `TenantOrder.fromJson`'s item mapping (`id`, `product_name`, `subtotal`,
/// `quantity`).
Map<String, dynamic> tenantOrderItemJson({
  required String id,
  String productName = 'Item',
  int subtotal = 10000,
  int quantity = 1,
}) => {
  'id': id,
  'product_name': productName,
  'subtotal': subtotal,
  'quantity': quantity,
};

/// Wraps [data] in the CMS success envelope every endpoint returns.
Map<String, dynamic> tenantEnvelope(Object? data) => {
  'meta': {
    'success': true,
    'message': 'Success',
    'code': 200,
    'trace_id': 'abc',
  },
  'data': data,
};

/// A [Dio] whose every request answers with [orders] in the list envelope.
Dio cannedOrderListDio(List<Map<String, dynamic>> orders) =>
    cannedDio(200, tenantEnvelope(orders));

/// A branch-scoped [FakeLocalStorage], as `TenantOrderBoard` requires.
FakeLocalStorage branchScopedStorage() =>
    FakeLocalStorage()..values[tenantBranchIdStorageKey] = testBranchId;

/// Canned `GET /v1/tenant-branches/{id}` response for [testBranchId] —
/// screens that resolve a real tenant name via `currentTenantBranchProvider`
/// (e.g. `TenantOrderHeader`) need this mocked too, or they'd fall through to
/// a real, unmocked network call. Matches the recurring `KFC Fried Chicken`
/// test tenant name used across the suite.
Dio tenantBranchDio({String branchName = 'KFC Fried Chicken'}) => cannedDio(
  200,
  tenantEnvelope({
    'id': testBranchId,
    'brand_id': 'brand-1',
    'brand_name': 'Janji Jiwa',
    'branch_name': branchName,
    'area_name': 'Downtown',
    'is_active': true,
    'created_at': '2026-08-07 09:16:37',
  }),
);

/// Provider overrides standing up a real `TenantOrderBoard` over [dio]: a
/// branch-scoped local storage, a real repository, a fake realtime service (a
/// widget test has no socket, and an un-faked one hangs the board's initial
/// fetch on an unmocked platform channel), and a canned branch fetch (so the
/// header's real tenant name resolves without hitting the network).
List<Override> tenantBoardOverrides({
  required Dio dio,
  TenantRealtimeService? realtime,
  FakeLocalStorage? storage,
  Dio? branchDio,
}) => [
  localStorageProvider.overrideWithValue(storage ?? branchScopedStorage()),
  tenantOrderRepositoryProvider.overrideWithValue(
    TenantOrderRepository(dio: dio),
  ),
  tenantRealtimeServiceProvider.overrideWithValue(
    realtime ?? FakeTenantRealtimeService(),
  ),
  tenantBranchRepositoryProvider.overrideWithValue(
    TenantBranchRepository(dio: branchDio ?? tenantBranchDio()),
  ),
];

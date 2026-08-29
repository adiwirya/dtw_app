import 'package:dio/dio.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_branch.dart';
import 'package:dtw_app/features/tenant/data/repositories/product_repository.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_branch_repository.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_order_repository.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'canned_dio.dart';
import 'fake_local_storage.dart';
import 'fake_tenant_realtime_service.dart';
import 'routed_dio.dart';

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
  String? tableNumber,
  String createdAt = '2026-08-07 09:24:08',
  int? broadcastEventId,
  List<Map<String, dynamic>> items = const [],
}) => {
  'id': id,
  'order_group_id': 'group-$id',
  'branch_id': testBranchId,
  'receipt_number': receiptNumber ?? 'RCP-$id',
  'table_number': ?tableNumber,
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

/// One `GET /v1/product-categories` list item.
Map<String, dynamic> productCategoryJson({
  required String id,
  required String name,
}) => {
  'id': id,
  'brand_id': 'brand-1',
  'brand_name': 'Janji Jiwa',
  'parent_category_id': null,
  'parent_category_name': null,
  'name': name,
  'sequence_order': 1,
  'is_active': true,
  'created_at': '2026-08-07 09:16:59',
  'updated_at': '2026-08-07 09:16:59',
};

/// One `GET /v1/products` list item (and the `POST /v1/products` response).
Map<String, dynamic> productJson({
  required String id,
  required String name,
  int totalPrice = 19900,
}) => {
  'id': id,
  'brand_id': 'brand-1',
  'brand_name': 'Janji Jiwa',
  'category_id': 'cat-1',
  'category_name': 'Nasi',
  'sku': null,
  'name': name,
  'description': null,
  'tags': null,
  // The real 11% PB1 split, not a 90/10 approximation: `total_price` is what
  // the customer pays and `dpp_price` is the base backed out of it. Keeping
  // these far apart is what makes a test asserting on 19900 fail if some code
  // path ever reads `dpp_price` instead.
  'dpp_price': totalPrice / 1.11,
  'pb1_percentage': 11,
  'pb1_price': totalPrice - totalPrice / 1.11,
  'total_price': totalPrice,
  'image_url': null,
  'is_active': true,
  'created_at': '2026-08-07 09:16:59',
  'updated_at': '2026-08-07 09:16:59',
};

/// The branch every tenant menu/variant test is scoped to.
TenantBranch tenantBranchFixture() => TenantBranch(
  id: testBranchId,
  brandId: 'brand-1',
  brandName: 'Janji Jiwa',
  branchName: 'Janji Jiwa',
  areaName: 'Downtown',
  isActive: true,
  createdAt: DateTime(2026, 8, 7),
);

/// Overrides for the tenant menu screens and the add-menu form: a seeded
/// branch plus a routed `ProductRepository` covering the product list,
/// per-branch availability, the category list and the create POST.
///
/// The add-menu form watches `productCategoriesProvider`, so any test that
/// pumps `TambahMenuScreen` needs this — otherwise the category fetch hangs on
/// the unmocked `flutter_secure_storage` channel and the dropdown is stuck on
/// its "Memuat kategori..." state.
///
/// [created] is the `POST /v1/products` response; [syncStatus] the status for
/// the modifier-group sync.
List<Override> tenantMenuOverrides({
  List<Map<String, dynamic>> products = const [],
  List<Map<String, dynamic>> categories = const [],
  Map<String, bool> availability = const {},
  Map<String, dynamic>? created,
  int syncStatus = 200,
}) {
  final branch = tenantBranchFixture();
  final dio = routedDio({
    // More specific keys first — RoutedAdapter matches the first key that is
    // a prefix of "METHOD path".
    'POST /v1/products/': (syncStatus, tenantEnvelope(null)),
    'POST /v1/products': (
      201,
      tenantEnvelope(created ?? productJson(id: 'new-1', name: 'Menu Baru')),
    ),
    '/v1/tenant-branches/$testBranchId/product-availability': (
      200,
      tenantEnvelope([
        for (final entry in availability.entries)
          {'id': entry.key, 'is_available': entry.value},
      ]),
    ),
    '/v1/product-categories': (200, tenantEnvelope(categories)),
    '/v1/products': (200, tenantEnvelope(products)),
  });
  return [
    currentTenantBranchProvider.overrideWith((ref) async => branch),
    productRepositoryProvider.overrideWithValue(ProductRepository(dio: dio)),
  ];
}

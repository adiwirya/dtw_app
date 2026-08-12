import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_order_repository.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_order_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/canned_dio.dart';
import '../../../support/fake_local_storage.dart';
import '../../../support/fake_tenant_realtime_service.dart';

Map<String, dynamic> _orderJson({
  required String id,
  required String status,
  int? broadcastEventId,
}) =>
    {
      'id': id,
      'order_group_id': 'group-$id',
      'branch_id': 'branch-1',
      'receipt_number': 'RCP-$id',
      'grand_total': 21000,
      'order_status': status,
      'created_at': '2026-08-07 09:24:08',
      'updated_at': '2026-08-07 09:24:08',
      'items': <dynamic>[],
      'broadcast_event_id': ?broadcastEventId,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLocalStorage storage;
  late FakeTenantRealtimeService realtime;
  late TenantOrderRepository repository;
  late ProviderContainer container;

  ProviderContainer buildContainer({
    required int statusCode,
    required Object? body,
  }) {
    storage = FakeLocalStorage()..values[tenantBranchIdStorageKey] = 'branch-1';
    realtime = FakeTenantRealtimeService();
    repository = TenantOrderRepository(dio: cannedDio(statusCode, body));
    final c = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        tenantOrderRepositoryProvider.overrideWithValue(repository),
        tenantRealtimeServiceProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(c.dispose);
    addTearDown(realtime.close);
    // tenantOrderBoardProvider autoDisposes (see the provider's dartdoc for
    // why that matters in production): without an active listener, Riverpod
    // schedules it for teardown as soon as a bare `container.read` call
    // returns, which would reset state between this test's `container.read`
    // statements. The real `TenantOrderScreen` keeps it alive by
    // continuously `ref.watch`-ing it while mounted; this listener mirrors
    // that so the provider survives for the lifetime of the test.
    c.listen(tenantOrderBoardProvider, (_, _) {});
    return c;
  }

  Object? listBody(List<Map<String, dynamic>> orders) => {
        'meta': {
          'success': true,
          'message': 'Success',
          'code': 200,
          'trace_id': 'abc',
        },
        'data': orders,
      };

  group('initial load', () {
    test('fetches once using the stored branch id', () async {
      container = buildContainer(
        statusCode: 200,
        body: listBody([_orderJson(id: '1', status: 'PENDING')]),
      );

      final orders = await container.read(tenantOrderBoardProvider.future);

      expect(orders, hasLength(1));
      expect(orders.single.id, '1');
    });

    test('surfaces a fetch failure as AsyncError', () async {
      container = buildContainer(
        statusCode: 500,
        body: {
          'meta': {
            'success': false,
            'message': 'Error',
            'code': 500,
            'trace_id': 'abc',
          },
        },
      );

      await expectLater(
        container.read(tenantOrderBoardProvider.future),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('realtime new-order delivery', () {
    test('an order.created event appends to the board', () async {
      container = buildContainer(
        statusCode: 200,
        body: listBody([_orderJson(id: '1', status: 'PENDING')]),
      );
      await container.read(tenantOrderBoardProvider.future);

      realtime.emitOrderCreated(_orderJson(id: '2', status: 'PENDING'));
      await Future<void>.delayed(Duration.zero);

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders.map((o) => o.id), containsAll(['1', '2']));
    });

    test('a duplicate order id from the stream does not double the list',
        () async {
      container = buildContainer(
        statusCode: 200,
        body: listBody([_orderJson(id: '1', status: 'PENDING')]),
      );
      await container.read(tenantOrderBoardProvider.future);

      realtime.emitOrderCreated(_orderJson(id: '1', status: 'PENDING'));
      await Future<void>.delayed(Duration.zero);

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders, hasLength(1));
    });

    test(
        'an order.created event during the initial fetch is merged, '
        'not dropped', () async {
      storage = FakeLocalStorage()
        ..values[tenantBranchIdStorageKey] = 'branch-1';
      realtime = FakeTenantRealtimeService();
      addTearDown(realtime.close);
      final fetchGate = Completer<void>();
      final fetchDio = cannedDio(
        200,
        listBody([_orderJson(id: '1', status: 'PENDING')]),
      );
      final delayedRepository = _DelayedFetchRepository(
        dio: fetchDio,
        fetchGate: fetchGate.future,
      );
      container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          tenantOrderRepositoryProvider.overrideWithValue(delayedRepository),
          tenantRealtimeServiceProvider.overrideWithValue(realtime),
        ],
      );
      addTearDown(container.dispose);
      container.listen(tenantOrderBoardProvider, (_, _) {});

      final orderBoardFuture = container.read(tenantOrderBoardProvider.future);
      // Let build() run up to (and suspend on) the gated fetchOrders call —
      // that's also where the orderCreated subscription gets wired up, so
      // this event lands squarely in the "fetch still in flight" window.
      await Future<void>.delayed(Duration.zero);

      realtime.emitOrderCreated(_orderJson(id: '2', status: 'PENDING'));
      await Future<void>.delayed(Duration.zero);

      fetchGate.complete();
      final orders = await orderBoardFuture;

      expect(orders.map((o) => o.id), containsAll(['1', '2']));
    });
  });

  group('accept / reject / markReady', () {
    test('accept optimistically moves an order to preparing then confirms',
        () async {
      container = buildContainer(
        statusCode: 200,
        body: listBody([_orderJson(id: '1', status: 'PENDING')]),
      );
      await container.read(tenantOrderBoardProvider.future);

      await container.read(tenantOrderBoardProvider.notifier).accept('1');

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders.single.status, TenantOrderStatus.preparing);
    });

    test('markReady moves a preparing order to ready', () async {
      container = buildContainer(
        statusCode: 200,
        body: listBody([_orderJson(id: '1', status: 'PREPARING')]),
      );
      await container.read(tenantOrderBoardProvider.future);

      await container.read(tenantOrderBoardProvider.notifier).markReady('1');

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders.single.status, TenantOrderStatus.ready);
    });

    test(
        'reject removes the order from the board '
        '(cancelled orders are not shown)', () async {
      container = buildContainer(
        statusCode: 200,
        body: listBody([_orderJson(id: '1', status: 'PENDING')]),
      );
      await container.read(tenantOrderBoardProvider.future);

      await container.read(tenantOrderBoardProvider.notifier).reject(
            '1',
            reason: 'Stok Habis',
          );

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders, isEmpty);
    });

    test('reject reverts (order reappears) and rethrows on API failure',
        () async {
      storage = FakeLocalStorage()
        ..values[tenantBranchIdStorageKey] = 'branch-1';
      realtime = FakeTenantRealtimeService();
      addTearDown(realtime.close);
      final fetchDio = cannedDio(
        200,
        listBody([_orderJson(id: '1', status: 'PENDING')]),
      );
      final failingRepository = _FailingUpdateRepository(dio: fetchDio);
      container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          tenantOrderRepositoryProvider.overrideWithValue(failingRepository),
          tenantRealtimeServiceProvider.overrideWithValue(realtime),
        ],
      );
      addTearDown(container.dispose);
      container.listen(tenantOrderBoardProvider, (_, _) {});
      await container.read(tenantOrderBoardProvider.future);

      await expectLater(
        container
            .read(tenantOrderBoardProvider.notifier)
            .reject('1', reason: 'Stok Habis'),
        throwsA(isA<ApiException>()),
      );

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders, hasLength(1));
      expect(orders.single.status, TenantOrderStatus.pending);
    });

    test('accept reverts the optimistic change and rethrows on API failure',
        () async {
      storage = FakeLocalStorage()
        ..values[tenantBranchIdStorageKey] = 'branch-1';
      realtime = FakeTenantRealtimeService();
      addTearDown(realtime.close);
      // First call (initial fetch) succeeds via one Dio instance; the
      // updateStatus call needs a *different* Dio wired to fail, so this
      // test builds the repository directly instead of via buildContainer.
      final fetchDio = cannedDio(
        200,
        listBody([_orderJson(id: '1', status: 'PENDING')]),
      );
      final failingRepository = _FailingUpdateRepository(dio: fetchDio);
      container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          tenantOrderRepositoryProvider.overrideWithValue(failingRepository),
          tenantRealtimeServiceProvider.overrideWithValue(realtime),
        ],
      );
      addTearDown(container.dispose);
      container.listen(tenantOrderBoardProvider, (_, _) {});
      await container.read(tenantOrderBoardProvider.future);

      await expectLater(
        container.read(tenantOrderBoardProvider.notifier).accept('1'),
        throwsA(isA<ApiException>()),
      );

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders.single.status, TenantOrderStatus.pending);
    });
  });
}

/// A repository whose [fetchOrders] delegates to a real (canned) [Dio] but
/// whose [updateStatus] always fails, so the rollback path can be tested in
/// isolation.
class _FailingUpdateRepository implements TenantOrderRepository {
  _FailingUpdateRepository({required Dio dio})
      : _delegate = TenantOrderRepository(dio: dio);

  final TenantOrderRepository _delegate;

  @override
  Future<List<TenantOrder>> fetchOrders({required String branchId}) =>
      _delegate.fetchOrders(branchId: branchId);

  @override
  Future<void> updateStatus(
    String orderId, {
    required TenantOrderStatus status,
    String? reason,
  }) {
    throw ApiException(message: 'Terjadi kesalahan. Coba lagi.');
  }

  @override
  Future<List<TenantOrder>> fetchMissedEvents({
    required String branchId,
    required int afterId,
  }) =>
      _delegate.fetchMissedEvents(branchId: branchId, afterId: afterId);
}

/// A repository whose [fetchOrders] delegates to a real (canned) [Dio] but
/// only resolves once [fetchGate] completes, so a test can deterministically
/// keep the initial fetch "in flight" long enough to exercise the
/// during-fetch realtime-event buffering path.
class _DelayedFetchRepository implements TenantOrderRepository {
  _DelayedFetchRepository({required Dio dio, required this.fetchGate})
      : _delegate = TenantOrderRepository(dio: dio);

  final TenantOrderRepository _delegate;
  final Future<void> fetchGate;

  @override
  Future<List<TenantOrder>> fetchOrders({required String branchId}) async {
    await fetchGate;
    return _delegate.fetchOrders(branchId: branchId);
  }

  @override
  Future<void> updateStatus(
    String orderId, {
    required TenantOrderStatus status,
    String? reason,
  }) =>
      _delegate.updateStatus(orderId, status: status, reason: reason);

  @override
  Future<List<TenantOrder>> fetchMissedEvents({
    required String branchId,
    required int afterId,
  }) =>
      _delegate.fetchMissedEvents(branchId: branchId, afterId: afterId);
}

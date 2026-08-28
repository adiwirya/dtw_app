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
import '../../../support/tenant_board.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLocalStorage storage;
  late FakeTenantRealtimeService realtime;
  late TenantOrderRepository repository;
  late CannedAdapter adapter;
  late ProviderContainer container;

  ProviderContainer buildContainer({
    required int statusCode,
    required Object? body,
  }) {
    storage = branchScopedStorage();
    realtime = FakeTenantRealtimeService();
    final dio = cannedDio(statusCode, body);
    adapter = dio.httpClientAdapter as CannedAdapter;
    repository = TenantOrderRepository(dio: dio);
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

  group('initial load', () {
    test('fetches once using the stored branch id', () async {
      container = buildContainer(
        statusCode: 200,
        body: tenantEnvelope([tenantOrderJson(id: '1', status: 'PENDING')]),
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
        body: tenantEnvelope([tenantOrderJson(id: '1', status: 'PENDING')]),
      );
      await container.read(tenantOrderBoardProvider.future);

      realtime.emitOrderCreated(tenantOrderJson(id: '2', status: 'PENDING'));
      await Future<void>.delayed(Duration.zero);

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders.map((o) => o.id), containsAll(['1', '2']));
    });

    test('a duplicate order id from the stream does not double the list',
        () async {
      container = buildContainer(
        statusCode: 200,
        body: tenantEnvelope([tenantOrderJson(id: '1', status: 'PENDING')]),
      );
      await container.read(tenantOrderBoardProvider.future);

      realtime.emitOrderCreated(tenantOrderJson(id: '1', status: 'PENDING'));
      await Future<void>.delayed(Duration.zero);

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders, hasLength(1));
    });

    test(
        'an order.created event during the initial fetch is merged, '
        'not dropped', () async {
      storage = branchScopedStorage();
      realtime = FakeTenantRealtimeService();
      addTearDown(realtime.close);
      final fetchGate = Completer<void>();
      final fetchDio = cannedDio(
        200,
        tenantEnvelope([tenantOrderJson(id: '1', status: 'PENDING')]),
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

      realtime.emitOrderCreated(tenantOrderJson(id: '2', status: 'PENDING'));
      await Future<void>.delayed(Duration.zero);

      fetchGate.complete();
      final orders = await orderBoardFuture;

      expect(orders.map((o) => o.id), containsAll(['1', '2']));
    });

    // Fix for a gap in the during-fetch buffer: it deduped buffered orders
    // against the FETCHED list but not against each other, so two events for
    // the same brand-new order inside the fetch window both survived and
    // rendered as duplicate rows.
    test('two during-fetch events for the same new order merge to one row',
        () async {
      storage = branchScopedStorage();
      realtime = FakeTenantRealtimeService();
      addTearDown(realtime.close);
      final fetchGate = Completer<void>();
      final delayedRepository = _DelayedFetchRepository(
        dio: cannedOrderListDio([
          tenantOrderJson(id: '1', status: 'PENDING'),
        ]),
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
      await Future<void>.delayed(Duration.zero);

      // Same id twice while the fetch is still in flight.
      realtime
        ..emitOrderCreated(tenantOrderJson(id: '2', status: 'PENDING'))
        ..emitOrderCreated(tenantOrderJson(id: '2', status: 'PENDING'));
      await Future<void>.delayed(Duration.zero);

      fetchGate.complete();
      final orders = await orderBoardFuture;

      expect(orders.map((o) => o.id), ['2', '1']);
      expect(orders.where((o) => o.id == '2'), hasLength(1));
    });
  });

  group('reconnect gap-fill', () {
    test('a reconnect replays missed events and merges them into the board',
        () async {
      storage = branchScopedStorage();
      realtime = FakeTenantRealtimeService();
      addTearDown(realtime.close);
      final replayRepository = _RecordingReplayRepository(
        dio: cannedOrderListDio([
          tenantOrderJson(id: '1', status: 'PENDING', broadcastEventId: 41),
        ]),
        missed: [
          // Already on the board — must be deduped away, not doubled.
          tenantOrderJson(id: '1', status: 'PENDING', broadcastEventId: 41),
          tenantOrderJson(id: '2', status: 'PENDING', broadcastEventId: 42),
        ],
      );
      container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          tenantOrderRepositoryProvider.overrideWithValue(replayRepository),
          tenantRealtimeServiceProvider.overrideWithValue(realtime),
        ],
      );
      addTearDown(container.dispose);
      container.listen(tenantOrderBoardProvider, (_, _) {});
      await container.read(tenantOrderBoardProvider.future);

      realtime.emitReconnected();
      await Future<void>.delayed(Duration.zero);

      // Called with the branch id and the highest broadcast id seen so far.
      expect(replayRepository.calls, [(branchId: 'branch-1', afterId: 41)]);
      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders.map((o) => o.id), ['2', '1']);
    });

    test('a reconnect before any broadcast id is known does not replay',
        () async {
      storage = branchScopedStorage();
      realtime = FakeTenantRealtimeService();
      addTearDown(realtime.close);
      // No broadcast_event_id anywhere, so there is no `after_id` to ask from.
      final replayRepository = _RecordingReplayRepository(
        dio: cannedOrderListDio([tenantOrderJson(id: '1', status: 'PENDING')]),
        missed: const [],
      );
      container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          tenantOrderRepositoryProvider.overrideWithValue(replayRepository),
          tenantRealtimeServiceProvider.overrideWithValue(realtime),
        ],
      );
      addTearDown(container.dispose);
      container.listen(tenantOrderBoardProvider, (_, _) {});
      await container.read(tenantOrderBoardProvider.future);

      realtime.emitReconnected();
      await Future<void>.delayed(Duration.zero);

      expect(replayRepository.calls, isEmpty);
    });

    // The gap-fill runs from a stream listener, so nothing awaits its future:
    // a throw used to escape as an uncaught async error. It must instead
    // leave the board on its last-known-good list.
    test('a failing gap-fill is swallowed and keeps the current list',
        () async {
      storage = branchScopedStorage();
      realtime = FakeTenantRealtimeService();
      addTearDown(realtime.close);
      final failingReplay = _FailingReplayRepository(
        dio: cannedOrderListDio([
          tenantOrderJson(id: '1', status: 'PENDING', broadcastEventId: 41),
        ]),
      );
      container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          tenantOrderRepositoryProvider.overrideWithValue(failingReplay),
          tenantRealtimeServiceProvider.overrideWithValue(realtime),
        ],
      );
      addTearDown(container.dispose);
      container.listen(tenantOrderBoardProvider, (_, _) {});
      await container.read(tenantOrderBoardProvider.future);

      realtime.emitReconnected();
      await Future<void>.delayed(Duration.zero);

      final board = container.read(tenantOrderBoardProvider);
      expect(board.hasError, isFalse);
      expect(board.value!.map((o) => o.id), ['1']);
    });
  });

  group('accept / reject / markReady', () {
    test('accept optimistically moves an order to preparing then confirms',
        () async {
      container = buildContainer(
        statusCode: 200,
        body: tenantEnvelope([tenantOrderJson(id: '1', status: 'PENDING')]),
      );
      await container.read(tenantOrderBoardProvider.future);

      await container.read(tenantOrderBoardProvider.notifier).accept('1');

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders.single.status, TenantOrderStatus.preparing);
    });

    test('markReady moves a preparing order to ready', () async {
      container = buildContainer(
        statusCode: 200,
        body: tenantEnvelope([tenantOrderJson(id: '1', status: 'PREPARING')]),
      );
      await container.read(tenantOrderBoardProvider.future);

      await container.read(tenantOrderBoardProvider.notifier).markReady('1');

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders.single.status, TenantOrderStatus.ready);
    });

    test(
        'reject removes the order from the board when every item is '
        'rejected (cancelled orders are not shown)', () async {
      container = buildContainer(
        statusCode: 200,
        body: tenantEnvelope([
          tenantOrderJson(
            id: '1',
            status: 'PENDING',
            items: [tenantOrderItemJson(id: 'item-1')],
          ),
        ]),
      );
      await container.read(tenantOrderBoardProvider.future);

      await container.read(tenantOrderBoardProvider.notifier).reject(
            '1',
            rejectedItemIds: ['item-1'],
          );

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders, isEmpty);
    });

    test(
        'reject moves the order to preparing when only some items are '
        'rejected', () async {
      container = buildContainer(
        statusCode: 200,
        body: tenantEnvelope([
          tenantOrderJson(
            id: '1',
            status: 'PENDING',
            items: [
              tenantOrderItemJson(id: 'item-1'),
              tenantOrderItemJson(id: 'item-2'),
            ],
          ),
        ]),
      );
      await container.read(tenantOrderBoardProvider.future);

      await container.read(tenantOrderBoardProvider.notifier).reject(
            '1',
            rejectedItemIds: ['item-1'],
          );

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders.single.status, TenantOrderStatus.preparing);
    });

    test('reject reverts (order reappears) and rethrows on API failure',
        () async {
      storage = branchScopedStorage();
      realtime = FakeTenantRealtimeService();
      addTearDown(realtime.close);
      final fetchDio = cannedDio(
        200,
        tenantEnvelope([tenantOrderJson(id: '1', status: 'PENDING')]),
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
            .reject('1', rejectedItemIds: const ['item-1']),
        throwsA(isA<ApiException>()),
      );

      final orders = container.read(tenantOrderBoardProvider).value!;
      expect(orders, hasLength(1));
      expect(orders.single.status, TenantOrderStatus.pending);
    });

    test('accept reverts the optimistic change and rethrows on API failure',
        () async {
      storage = branchScopedStorage();
      realtime = FakeTenantRealtimeService();
      addTearDown(realtime.close);
      // First call (initial fetch) succeeds via one Dio instance; the
      // updateStatus call needs a *different* Dio wired to fail, so this
      // test builds the repository directly instead of via buildContainer.
      final fetchDio = cannedDio(
        200,
        tenantEnvelope([tenantOrderJson(id: '1', status: 'PENDING')]),
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

  // These two used to `return` silently, which is what let the reject screen
  // show "berhasil" feedback for a rejection the backend never heard about.
  // A mutation aimed at an order that is not on the board is a bug and has to
  // surface — the screens catch it and show a SnackBar.
  group('mutations targeting an order that is not on the board', () {
    test('reject on an unknown order id throws instead of no-oping', () async {
      container = buildContainer(
        statusCode: 200,
        body: tenantEnvelope([tenantOrderJson(id: '1', status: 'PENDING')]),
      );
      await container.read(tenantOrderBoardProvider.future);
      final requestsBefore = adapter.lastRequest;

      await expectLater(
        container
            .read(tenantOrderBoardProvider.notifier)
            .reject('nope', rejectedItemIds: const ['item-1']),
        throwsA(isA<StateError>()),
      );

      // The board is untouched and no PATCH was attempted.
      expect(
        container.read(tenantOrderBoardProvider).value!.single.id,
        '1',
      );
      expect(adapter.lastRequest, same(requestsBefore));
    });

    test('accept on an unknown order id throws instead of no-oping', () async {
      container = buildContainer(
        statusCode: 200,
        body: tenantEnvelope([tenantOrderJson(id: '1', status: 'PENDING')]),
      );
      await container.read(tenantOrderBoardProvider.future);

      await expectLater(
        container.read(tenantOrderBoardProvider.notifier).accept('nope'),
        throwsA(isA<StateError>()),
      );
    });

    test('markReady before the board has loaded throws', () async {
      container = buildContainer(
        statusCode: 200,
        body: tenantEnvelope([tenantOrderJson(id: '1', status: 'PENDING')]),
      );
      // Deliberately NOT awaiting the initial fetch: `state.value` is still
      // null here.
      await expectLater(
        container.read(tenantOrderBoardProvider.notifier).markReady('1'),
        throwsA(isA<StateError>()),
      );
    });
  });
}

/// A repository whose [fetchOrders] delegates to a real (canned) [Dio] but
/// whose [updateStatus] and [processOrder] always fail, so the rollback path
/// can be tested in isolation.
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
  }) {
    throw ApiException(message: 'Terjadi kesalahan. Coba lagi.');
  }

  @override
  Future<void> processOrder(
    String orderId, {
    required List<String> rejectedItemIds,
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

/// A repository that records every [fetchMissedEvents] call and answers with a
/// fixed replay payload, so the reconnect gap-fill can be asserted on both its
/// arguments and its merge behaviour.
class _RecordingReplayRepository implements TenantOrderRepository {
  _RecordingReplayRepository({required Dio dio, required this.missed})
      : _delegate = TenantOrderRepository(dio: dio);

  final TenantOrderRepository _delegate;

  /// Orders the replay endpoint "missed" while the socket was down.
  final List<Map<String, dynamic>> missed;

  final List<({String branchId, int afterId})> calls = [];

  @override
  Future<List<TenantOrder>> fetchOrders({required String branchId}) =>
      _delegate.fetchOrders(branchId: branchId);

  @override
  Future<void> updateStatus(
    String orderId, {
    required TenantOrderStatus status,
  }) =>
      _delegate.updateStatus(orderId, status: status);

  @override
  Future<void> processOrder(
    String orderId, {
    required List<String> rejectedItemIds,
  }) =>
      _delegate.processOrder(orderId, rejectedItemIds: rejectedItemIds);

  @override
  Future<List<TenantOrder>> fetchMissedEvents({
    required String branchId,
    required int afterId,
  }) async {
    calls.add((branchId: branchId, afterId: afterId));
    return missed.map(TenantOrder.fromJson).toList();
  }
}

/// A repository whose replay endpoint always fails, so the gap-fill's
/// swallow-and-keep-current-list path can be exercised.
class _FailingReplayRepository implements TenantOrderRepository {
  _FailingReplayRepository({required Dio dio})
      : _delegate = TenantOrderRepository(dio: dio);

  final TenantOrderRepository _delegate;

  @override
  Future<List<TenantOrder>> fetchOrders({required String branchId}) =>
      _delegate.fetchOrders(branchId: branchId);

  @override
  Future<void> updateStatus(
    String orderId, {
    required TenantOrderStatus status,
  }) =>
      _delegate.updateStatus(orderId, status: status);

  @override
  Future<void> processOrder(
    String orderId, {
    required List<String> rejectedItemIds,
  }) =>
      _delegate.processOrder(orderId, rejectedItemIds: rejectedItemIds);

  @override
  Future<List<TenantOrder>> fetchMissedEvents({
    required String branchId,
    required int afterId,
  }) =>
      throw ApiException(message: 'Terjadi kesalahan. Coba lagi.');
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
  }) =>
      _delegate.updateStatus(orderId, status: status);

  @override
  Future<void> processOrder(
    String orderId, {
    required List<String> rejectedItemIds,
  }) =>
      _delegate.processOrder(orderId, rejectedItemIds: rejectedItemIds);

  @override
  Future<List<TenantOrder>> fetchMissedEvents({
    required String branchId,
    required int afterId,
  }) =>
      _delegate.fetchMissedEvents(branchId: branchId, afterId: afterId);
}

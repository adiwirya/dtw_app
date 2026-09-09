import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/realtime/busboy_realtime_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/order/data/models/delivery.dart';
import 'package:dtw_app/features/order/data/repositories/busboy_delivery_repository.dart';
import 'package:dtw_app/features/order/presentation/providers/order_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/busboy_board.dart';
import '../../../../support/canned_dio.dart';
import '../../../../support/fake_busboy_realtime_service.dart';
import '../../../../support/fake_local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLocalStorage storage;
  late ProviderContainer container;

  ProviderContainer buildContainer(List<Map<String, dynamic>> deliveries) {
    storage = zoneScopedStorage();
    final c = ProviderContainer(
      overrides: busboyBoardOverrides(dio: cannedDeliveryListDio(deliveries)),
    );
    addTearDown(c.dispose);
    // Mirrors the tenant board tests: keeps the autoDispose provider alive
    // for the lifetime of the test instead of tearing down between reads.
    c.listen(orderBoardNotifierProvider, (_, _) {});
    return c;
  }

  group('initial load', () {
    test('fetches once using the stored zone id', () async {
      container = buildContainer([
        deliveryJson(id: '1', status: 'PENDING_PICKUP'),
      ]);

      final deliveries = await container.read(
        orderBoardNotifierProvider.future,
      );

      expect(deliveries, hasLength(1));
      expect(deliveries.single.id, '1');
    });

    test('surfaces a fetch failure as AsyncError', () async {
      storage = zoneScopedStorage();
      container = ProviderContainer(
        overrides: busboyBoardOverrides(
          dio: cannedDio(500, {
            'meta': {
              'success': false,
              'message': 'Error',
              'code': 500,
              'trace_id': 'abc',
            },
          }),
          storage: storage,
        ),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(orderBoardNotifierProvider.future),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('realtime new-delivery delivery', () {
    late FakeBusboyRealtimeService realtime;

    ProviderContainer buildRealtimeContainer(
      List<Map<String, dynamic>> deliveries,
    ) {
      storage = zoneScopedStorage();
      realtime = FakeBusboyRealtimeService();
      addTearDown(realtime.close);
      final c = ProviderContainer(
        overrides: busboyBoardOverrides(
          dio: cannedDeliveryListDio(deliveries),
          storage: storage,
          realtime: realtime,
        ),
      );
      addTearDown(c.dispose);
      c.listen(orderBoardNotifierProvider, (_, _) {});
      return c;
    }

    test('a delivery.created event appends to the board', () async {
      container = buildRealtimeContainer([
        deliveryJson(id: '1', status: 'PENDING_PICKUP'),
      ]);
      await container.read(orderBoardNotifierProvider.future);

      realtime.emitDeliveryCreated(
        deliveryJson(id: '2', status: 'PENDING_PICKUP'),
      );
      await Future<void>.delayed(Duration.zero);

      final deliveries = container.read(orderBoardNotifierProvider).value!;
      expect(deliveries.map((d) => d.id), containsAll(['1', '2']));
    });

    test(
      'a duplicate delivery id from the stream does not double the list',
      () async {
        container = buildRealtimeContainer([
          deliveryJson(id: '1', status: 'PENDING_PICKUP'),
        ]);
        await container.read(orderBoardNotifierProvider.future);

        realtime.emitDeliveryCreated(
          deliveryJson(id: '1', status: 'PENDING_PICKUP'),
        );
        await Future<void>.delayed(Duration.zero);

        final deliveries = container.read(orderBoardNotifierProvider).value!;
        expect(deliveries, hasLength(1));
      },
    );

    test('a delivery.created event during the initial fetch is merged, '
        'not dropped', () async {
      storage = zoneScopedStorage();
      realtime = FakeBusboyRealtimeService();
      addTearDown(realtime.close);
      final fetchGate = Completer<void>();
      final delayedRepository = _DelayedFetchRepository(
        dio: cannedDeliveryListDio([
          deliveryJson(id: '1', status: 'PENDING_PICKUP'),
        ]),
        fetchGate: fetchGate.future,
      );
      container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          busboyDeliveryRepositoryProvider.overrideWithValue(delayedRepository),
          busboyRealtimeServiceProvider.overrideWithValue(realtime),
        ],
      );
      addTearDown(container.dispose);
      container.listen(orderBoardNotifierProvider, (_, _) {});

      final boardFuture = container.read(orderBoardNotifierProvider.future);
      // Let build() run up to (and suspend on) the gated fetchDeliveries
      // call — that's also where the deliveryCreated subscription gets
      // wired up, so this event lands squarely in the "fetch still in
      // flight" window.
      await Future<void>.delayed(Duration.zero);

      realtime.emitDeliveryCreated(
        deliveryJson(id: '2', status: 'PENDING_PICKUP'),
      );
      await Future<void>.delayed(Duration.zero);

      fetchGate.complete();
      final deliveries = await boardFuture;

      expect(deliveries.map((d) => d.id), containsAll(['1', '2']));
    });
  });

  group('realtime delivery updates (another busboy claims/completes)', () {
    late FakeBusboyRealtimeService realtime;

    ProviderContainer buildRealtimeContainer(
      List<Map<String, dynamic>> deliveries,
    ) {
      storage = zoneScopedStorage();
      realtime = FakeBusboyRealtimeService();
      addTearDown(realtime.close);
      final c = ProviderContainer(
        overrides: busboyBoardOverrides(
          dio: cannedDeliveryListDio(deliveries),
          storage: storage,
          realtime: realtime,
        ),
      );
      addTearDown(c.dispose);
      c.listen(orderBoardNotifierProvider, (_, _) {});
      return c;
    }

    test(
      'a delivery.claimed event moves it to Antar on this device too',
      () async {
        container = buildRealtimeContainer([
          deliveryJson(id: '1', status: 'PENDING_PICKUP'),
        ]);
        await container.read(orderBoardNotifierProvider.future);

        realtime.emitDeliveryClaimed(deliveryJson(id: '1', status: 'CLAIMED'));
        await Future<void>.delayed(Duration.zero);

        final deliveries = container.read(orderBoardNotifierProvider).value!;
        expect(deliveries.single.status, DeliveryStatus.claimed);
      },
    );

    test(
      'a delivery.completed event moves it to Selesai on this device too',
      () async {
        container = buildRealtimeContainer([
          deliveryJson(id: '1', status: 'CLAIMED'),
        ]);
        await container.read(orderBoardNotifierProvider.future);

        realtime.emitDeliveryCompleted(
          deliveryJson(id: '1', status: 'DELIVERED'),
        );
        await Future<void>.delayed(Duration.zero);

        final deliveries = container.read(orderBoardNotifierProvider).value!;
        expect(deliveries.single.status, DeliveryStatus.delivered);
      },
    );

    test('an update for a delivery not on the board is ignored', () async {
      container = buildRealtimeContainer([
        deliveryJson(id: '1', status: 'PENDING_PICKUP'),
      ]);
      await container.read(orderBoardNotifierProvider.future);

      realtime.emitDeliveryClaimed(deliveryJson(id: 'nope', status: 'CLAIMED'));
      await Future<void>.delayed(Duration.zero);

      final deliveries = container.read(orderBoardNotifierProvider).value!;
      expect(deliveries.map((d) => d.id), ['1']);
    });

    test(
      'an update before the board has loaded is dropped, not crashed',
      () async {
        storage = zoneScopedStorage();
        realtime = FakeBusboyRealtimeService();
        addTearDown(realtime.close);
        final container = ProviderContainer(
          overrides: busboyBoardOverrides(
            dio: cannedDeliveryListDio([
              deliveryJson(id: '1', status: 'PENDING_PICKUP'),
            ]),
            storage: storage,
            realtime: realtime,
          ),
        );
        addTearDown(container.dispose);
        container.listen(orderBoardNotifierProvider, (_, _) {});

        // Deliberately not awaiting the initial fetch yet.
        realtime.emitDeliveryClaimed(deliveryJson(id: '1', status: 'CLAIMED'));
        await Future<void>.delayed(Duration.zero);

        final deliveries = await container.read(
          orderBoardNotifierProvider.future,
        );
        expect(deliveries.single.status, DeliveryStatus.pendingPickup);
      },
    );
  });

  group('orderBoardFrom', () {
    test('buckets deliveries into baru/antar/selesai by status', () {
      final deliveries = [
        Delivery.fromJson(deliveryJson(id: '1', status: 'PENDING_PICKUP')),
        Delivery.fromJson(deliveryJson(id: '2', status: 'CLAIMED')),
        Delivery.fromJson(deliveryJson(id: '3', status: 'DELIVERED')),
      ];

      final board = orderBoardFrom(deliveries);

      expect(board.baru.map((o) => o.orderId), ['1']);
      expect(board.antar.map((o) => o.orderId), ['2']);
      expect(board.selesai.map((o) => o.orderId), ['3']);
    });
  });

  group('claim / deliver', () {
    test(
      'claim optimistically moves a delivery to claimed then confirms',
      () async {
        container = buildContainer([
          deliveryJson(id: '1', status: 'PENDING_PICKUP'),
        ]);
        await container.read(orderBoardNotifierProvider.future);

        await container.read(orderBoardNotifierProvider.notifier).claim('1');

        final deliveries = container.read(orderBoardNotifierProvider).value!;
        expect(deliveries.single.status, DeliveryStatus.claimed);
      },
    );

    test('deliver moves a claimed delivery to delivered', () async {
      container = buildContainer([deliveryJson(id: '1', status: 'CLAIMED')]);
      await container.read(orderBoardNotifierProvider.future);

      await container.read(orderBoardNotifierProvider.notifier).deliver('1');

      final deliveries = container.read(orderBoardNotifierProvider).value!;
      expect(deliveries.single.status, DeliveryStatus.delivered);
    });

    test('claim reverts and rethrows on API failure', () async {
      storage = zoneScopedStorage();
      final fetchDio = cannedDeliveryListDio([
        deliveryJson(id: '1', status: 'PENDING_PICKUP'),
      ]);
      final failing = _FailingRepository(dio: fetchDio);
      container = ProviderContainer(
        overrides: [
          ...busboyBoardOverrides(dio: fetchDio, storage: storage),
          busboyDeliveryRepositoryProvider.overrideWithValue(failing),
        ],
      );
      addTearDown(container.dispose);
      container.listen(orderBoardNotifierProvider, (_, _) {});
      await container.read(orderBoardNotifierProvider.future);

      await expectLater(
        container.read(orderBoardNotifierProvider.notifier).claim('1'),
        throwsA(isA<ApiException>()),
      );

      final deliveries = container.read(orderBoardNotifierProvider).value!;
      expect(deliveries.single.status, DeliveryStatus.pendingPickup);
    });

    test(
      'claim on an unknown delivery id throws instead of no-oping',
      () async {
        container = buildContainer([
          deliveryJson(id: '1', status: 'PENDING_PICKUP'),
        ]);
        await container.read(orderBoardNotifierProvider.future);

        await expectLater(
          container.read(orderBoardNotifierProvider.notifier).claim('nope'),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('deliver before the board has loaded throws', () async {
      storage = zoneScopedStorage();
      container = ProviderContainer(
        overrides: busboyBoardOverrides(
          dio: cannedDeliveryListDio([
            deliveryJson(id: '1', status: 'CLAIMED'),
          ]),
          storage: storage,
        ),
      );
      addTearDown(container.dispose);
      // Deliberately NOT awaiting the initial fetch: `state.value` is still
      // null here.
      await expectLater(
        container.read(orderBoardNotifierProvider.notifier).deliver('1'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('claim limit (max active deliveries per busboy)', () {
    test('rejects a 3rd claim once this busboy already has 2 active',
        () async {
      container = ProviderContainer(
        overrides: busboyBoardOverrides(
          dio: cannedDeliveryListDio([
            deliveryJson(id: '1', status: 'CLAIMED', busboyUserId: 'me'),
            deliveryJson(id: '2', status: 'CLAIMED', busboyUserId: 'me'),
            deliveryJson(id: '3', status: 'PENDING_PICKUP'),
          ]),
          sessionUserId: 'me',
        ),
      );
      addTearDown(container.dispose);
      container.listen(orderBoardNotifierProvider, (_, _) {});
      await container.read(orderBoardNotifierProvider.future);

      await expectLater(
        container.read(orderBoardNotifierProvider.notifier).claim('3'),
        throwsA(isA<ApiException>()),
      );

      // Rejected before the API call: no optimistic update stuck around.
      final deliveries = container.read(orderBoardNotifierProvider).value!;
      expect(
        deliveries.firstWhere((d) => d.id == '3').status,
        DeliveryStatus.pendingPickup,
      );
    });

    test('allows claiming while under the limit', () async {
      container = ProviderContainer(
        overrides: busboyBoardOverrides(
          dio: cannedDeliveryListDio([
            deliveryJson(id: '1', status: 'CLAIMED', busboyUserId: 'me'),
            deliveryJson(id: '2', status: 'PENDING_PICKUP'),
          ]),
          sessionUserId: 'me',
        ),
      );
      addTearDown(container.dispose);
      container.listen(orderBoardNotifierProvider, (_, _) {});
      await container.read(orderBoardNotifierProvider.future);

      await container.read(orderBoardNotifierProvider.notifier).claim('2');

      final deliveries = container.read(orderBoardNotifierProvider).value!;
      expect(
        deliveries.firstWhere((d) => d.id == '2').status,
        DeliveryStatus.claimed,
      );
    });

    test(
        "another busboy's active claims don't count against this device's "
        'limit', () async {
      container = ProviderContainer(
        overrides: busboyBoardOverrides(
          dio: cannedDeliveryListDio([
            deliveryJson(id: '1', status: 'CLAIMED', busboyUserId: 'other-1'),
            deliveryJson(id: '2', status: 'CLAIMED', busboyUserId: 'other-2'),
            deliveryJson(id: '3', status: 'PENDING_PICKUP'),
          ]),
          sessionUserId: 'me',
        ),
      );
      addTearDown(container.dispose);
      container.listen(orderBoardNotifierProvider, (_, _) {});
      await container.read(orderBoardNotifierProvider.future);

      await container.read(orderBoardNotifierProvider.notifier).claim('3');

      final deliveries = container.read(orderBoardNotifierProvider).value!;
      expect(
        deliveries.firstWhere((d) => d.id == '3').status,
        DeliveryStatus.claimed,
      );
    });

    test(
        'stamps this busboy on the optimistic claim, so a rapid second claim '
        'is rejected before the server confirms the first', () async {
      container = ProviderContainer(
        overrides: busboyBoardOverrides(
          dio: cannedDeliveryListDio([
            deliveryJson(id: '1', status: 'CLAIMED', busboyUserId: 'me'),
            deliveryJson(id: '2', status: 'PENDING_PICKUP'),
            deliveryJson(id: '3', status: 'PENDING_PICKUP'),
          ]),
          sessionUserId: 'me',
        ),
      );
      addTearDown(container.dispose);
      container.listen(orderBoardNotifierProvider, (_, _) {});
      await container.read(orderBoardNotifierProvider.future);

      // Not awaited: the optimistic update inside `claim` applies
      // synchronously (before its first `await`), so `claim('3')` right
      // after already sees delivery '2' as claimed-by-me, without needing
      // the server to have confirmed it yet.
      unawaited(container.read(orderBoardNotifierProvider.notifier).claim('2'));

      await expectLater(
        container.read(orderBoardNotifierProvider.notifier).claim('3'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('orderDetail', () {
    test('finds the delivery by id and maps it to OrderDetail', () async {
      container = buildContainer([
        deliveryJson(
          id: '1',
          status: 'PENDING_PICKUP',
          orders: [
            deliveryOrderJson(
              orderId: 'order-1',
              items: [deliveryItemJson(productName: 'Es Kopi', quantity: 2)],
            ),
          ],
        ),
      ]);
      await container.read(orderBoardNotifierProvider.future);

      final detail = container.read(orderDetailProvider('1'));

      expect(detail, isNotNull);
      expect(detail!.items.single.name, 'Es Kopi');
    });

    test('returns null for an id not on the board', () async {
      container = buildContainer([
        deliveryJson(id: '1', status: 'PENDING_PICKUP'),
      ]);
      await container.read(orderBoardNotifierProvider.future);

      expect(container.read(orderDetailProvider('nope')), isNull);
    });
  });
}

/// A repository whose [claim] always fails, so the rollback path can be
/// tested in isolation.
class _FailingRepository implements BusboyDeliveryRepository {
  _FailingRepository({required Dio dio})
    : _delegate = BusboyDeliveryRepository(dio: dio);

  final BusboyDeliveryRepository _delegate;

  @override
  Future<List<Delivery>> fetchDeliveries({DeliveryStatus? status}) =>
      _delegate.fetchDeliveries(status: status);

  @override
  Future<void> claim(String deliveryId) =>
      throw ApiException(message: 'Terjadi kesalahan. Coba lagi.');

  @override
  Future<void> complete(String deliveryId) => _delegate.complete(deliveryId);
}

/// A repository whose [fetchDeliveries] only resolves once [fetchGate]
/// completes, so a test can deterministically keep the initial fetch "in
/// flight" long enough to exercise the during-fetch realtime-event buffering
/// path.
class _DelayedFetchRepository implements BusboyDeliveryRepository {
  _DelayedFetchRepository({required Dio dio, required this.fetchGate})
    : _delegate = BusboyDeliveryRepository(dio: dio);

  final BusboyDeliveryRepository _delegate;
  final Future<void> fetchGate;

  @override
  Future<List<Delivery>> fetchDeliveries({DeliveryStatus? status}) async {
    await fetchGate;
    return _delegate.fetchDeliveries(status: status);
  }

  @override
  Future<void> claim(String deliveryId) => _delegate.claim(deliveryId);

  @override
  Future<void> complete(String deliveryId) => _delegate.complete(deliveryId);
}

import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/features/order/data/models/delivery.dart';
import 'package:dtw_app/features/riwayat/data/models/riwayat_models.dart';
import 'package:dtw_app/features/riwayat/presentation/providers/riwayat_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/busboy_board.dart';
import '../../../../support/canned_dio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  group('RiwayatBoard', () {
    test('fetches DELIVERED deliveries using the stored zone id', () async {
      container = ProviderContainer(
        overrides: busboyBoardOverrides(
          dio: cannedDeliveryListDio([
            deliveryJson(id: '1', status: 'DELIVERED'),
          ]),
        ),
      );
      addTearDown(container.dispose);
      container.listen(riwayatBoardProvider, (_, _) {});

      final deliveries = await container.read(riwayatBoardProvider.future);

      expect(deliveries, hasLength(1));
      expect(deliveries.single.id, '1');
    });

    test('surfaces a fetch failure as AsyncError', () async {
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
        ),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(riwayatBoardProvider.future),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('riwayatDaysFrom', () {
    final now = DateTime(2026, 8, 27, 12);
    const today = '2026-08-27 10:00:00';
    const yesterday = '2026-08-26 10:00:00';
    const eightDaysAgo = '2026-08-19 10:00:00';

    List<Delivery> deliveries() => [
      Delivery.fromJson(
        deliveryJson(id: '1', status: 'DELIVERED', deliveredAt: today),
      ),
      Delivery.fromJson(
        deliveryJson(id: '2', status: 'DELIVERED', deliveredAt: today),
      ),
      Delivery.fromJson(
        deliveryJson(id: '3', status: 'DELIVERED', deliveredAt: yesterday),
      ),
      Delivery.fromJson(
        deliveryJson(
          id: '4',
          status: 'DELIVERED',
          deliveredAt: eightDaysAgo,
        ),
      ),
    ];

    test('hariIni returns only today, newest bucket first', () {
      final days = riwayatDaysFrom(deliveries(), RiwayatRange.hariIni, now);

      expect(days, hasLength(1));
      expect(days.single.date, '27 Agustus 2026');
      expect(days.single.entries.map((e) => e.id), ['1', '2']);
    });

    test('kemarin returns only yesterday', () {
      final days = riwayatDaysFrom(deliveries(), RiwayatRange.kemarin, now);

      expect(days, hasLength(1));
      expect(days.single.date, '26 Agustus 2026');
      expect(days.single.entries.map((e) => e.id), ['3']);
    });

    test('tujuhHari includes today and yesterday, excludes 8 days ago', () {
      final days = riwayatDaysFrom(deliveries(), RiwayatRange.tujuhHari, now);

      expect(days.map((d) => d.date), ['27 Agustus 2026', '26 Agustus 2026']);
      expect(
        days.expand((d) => d.entries).map((e) => e.id),
        containsAll(['1', '2', '3']),
      );
      expect(
        days.expand((d) => d.entries).map((e) => e.id),
        isNot(contains('4')),
      );
    });

    test('an empty delivery list buckets to no groups', () {
      expect(riwayatDaysFrom(const [], RiwayatRange.hariIni, now), isEmpty);
    });
  });

  group('riwayatDetailProvider', () {
    test('finds the delivery by id and maps it to CompletedOrderDetail',
        () async {
      container = ProviderContainer(
        overrides: busboyBoardOverrides(
          dio: cannedDeliveryListDio([
            deliveryJson(
              id: '1',
              status: 'DELIVERED',
              orders: [
                deliveryOrderJson(
                  orderId: 'order-1',
                  items: [deliveryItemJson(productName: 'Es Kopi')],
                ),
              ],
            ),
          ]),
        ),
      );
      addTearDown(container.dispose);
      container.listen(riwayatBoardProvider, (_, _) {});
      await container.read(riwayatBoardProvider.future);

      final detail = container.read(riwayatDetailProvider('1'));

      expect(detail, isNotNull);
      expect(detail!.lineItems.single.name, 'Es Kopi');
    });

    test('returns null for an id not on the board', () async {
      container = ProviderContainer(
        overrides: busboyBoardOverrides(
          dio: cannedDeliveryListDio([
            deliveryJson(id: '1', status: 'DELIVERED'),
          ]),
        ),
      );
      addTearDown(container.dispose);
      container.listen(riwayatBoardProvider, (_, _) {});
      await container.read(riwayatBoardProvider.future);

      expect(container.read(riwayatDetailProvider('nope')), isNull);
    });
  });
}

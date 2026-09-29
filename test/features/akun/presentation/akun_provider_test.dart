import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/features/akun/presentation/providers/akun_provider.dart';
import 'package:dtw_app/features/order/data/repositories/busboy_delivery_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/canned_dio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('busboyRatingProvider', () {
    test('returns null without hitting the network when no user id is known',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final rating = await container.read(busboyRatingProvider.future);

      expect(rating, isNull);
    });

    test('fetches and formats the average rating for the session user',
        () async {
      final dio = cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Success',
          'code': 200,
          'trace_id': 'abc',
        },
        'data': {'average': 4.8, 'count': 30},
      });
      final container = ProviderContainer(
        overrides: [
          sessionUserIdProvider.overrideWith((ref) => 'user-1'),
          busboyDeliveryRepositoryProvider.overrideWithValue(
            BusboyDeliveryRepository(dio: dio),
          ),
        ],
      );
      addTearDown(container.dispose);

      final rating = await container.read(busboyRatingProvider.future);

      expect(rating, '4.8');
      expect(
        (dio.httpClientAdapter as CannedAdapter).lastRequest!.path,
        '/v1/busboys/user-1/rating',
      );
    });

    test('degrades to null when the fetch fails', () async {
      final dio = cannedDio(500, {
        'meta': {
          'success': false,
          'message': 'Error',
          'code': 500,
          'trace_id': 'abc',
        },
      });
      final container = ProviderContainer(
        overrides: [
          sessionUserIdProvider.overrideWith((ref) => 'user-1'),
          busboyDeliveryRepositoryProvider.overrideWithValue(
            BusboyDeliveryRepository(dio: dio),
          ),
        ],
      );
      addTearDown(container.dispose);

      final rating = await container.read(busboyRatingProvider.future);

      expect(rating, isNull);
    });
  });

  group('akunAccountProvider', () {
    test('Rating Pelanggan stat defaults to "-" without a fetched rating',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final account = container.read(akunAccountProvider);

      final stat =
          account.stats.firstWhere((s) => s.label == 'Rating Pelanggan');
      expect(stat.value, '-');
      expect(stat.showStar, isFalse);
    });

    test('Rating Pelanggan stat shows the fetched value with a star',
        () async {
      final dio = cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Success',
          'code': 200,
          'trace_id': 'abc',
        },
        'data': {'average': 4.8, 'count': 30},
      });
      final container = ProviderContainer(
        overrides: [
          sessionUserIdProvider.overrideWith((ref) => 'user-1'),
          busboyDeliveryRepositoryProvider.overrideWithValue(
            BusboyDeliveryRepository(dio: dio),
          ),
        ],
      );
      addTearDown(container.dispose);
      // Mirrors how AkunScreen keeps this alive in production: watching
      // akunAccountProvider (which itself watches busboyRatingProvider)
      // continuously, rather than a one-off disconnected read that would
      // let the autoDispose rating provider reset between reads.
      container.listen(akunAccountProvider, (_, _) {});

      await container.read(busboyRatingProvider.future);
      final account = container.read(akunAccountProvider);

      final stat =
          account.stats.firstWhere((s) => s.label == 'Rating Pelanggan');
      expect(stat.value, '4.8');
      expect(stat.showStar, isTrue);
    });
  });
}

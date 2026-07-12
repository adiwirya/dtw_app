import 'package:dtw_app/features/tenant/presentation/providers/tenant_order_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

int _countOf(
  ProviderContainer container,
  IncomingOrderStatus status,
) =>
    container
        .read(tenantOrderBoardProvider)
        .where((order) => order.status == status)
        .length;

void main() {
  // The shared flutter_test_config loads fonts in setUpAll, which needs the
  // binding; pure unit tests don't otherwise initialise it.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TenantOrderBoard (UI-only mock transitions)', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('seeds two baru, one diproses and one selesai order', () {
      expect(_countOf(container, IncomingOrderStatus.baru), 2);
      expect(_countOf(container, IncomingOrderStatus.diproses), 1);
      expect(_countOf(container, IncomingOrderStatus.selesai), 1);
    });

    test('accept() promotes a matching Baru order to Diproses', () {
      container.read(tenantOrderBoardProvider.notifier).accept('92842');

      expect(_countOf(container, IncomingOrderStatus.baru), 1);
      expect(_countOf(container, IncomingOrderStatus.diproses), 2);
    });

    test('markReady() promotes a matching Diproses order to Selesai', () {
      container.read(tenantOrderBoardProvider.notifier).markReady('92842');

      expect(_countOf(container, IncomingOrderStatus.diproses), 0);
      expect(_countOf(container, IncomingOrderStatus.selesai), 2);
    });

    test('reject() advances a matching Baru order to Diproses', () {
      container.read(tenantOrderBoardProvider.notifier).reject(
            '92842',
            reason: 'Stok Habis',
            rejectedItemNames: const ['Es Lemon Tea'],
          );

      expect(_countOf(container, IncomingOrderStatus.baru), 1);
      expect(_countOf(container, IncomingOrderStatus.diproses), 2);
    });

    test('reject() is a no-op for an unknown order id', () {
      final before = container.read(tenantOrderBoardProvider);

      container
          .read(tenantOrderBoardProvider.notifier)
          .reject('00000', reason: 'Stok Habis');

      expect(container.read(tenantOrderBoardProvider), same(before));
    });

    test('accept() is a no-op for an unknown order id', () {
      final before = container.read(tenantOrderBoardProvider);

      container.read(tenantOrderBoardProvider.notifier).accept('00000');

      expect(container.read(tenantOrderBoardProvider), same(before));
    });
  });
}

import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_order_repository.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_order_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/canned_dio.dart';
import '../../../support/fake_local_storage.dart';
import '../../../support/fake_tenant_realtime_service.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';

Map<String, dynamic> _orderJson({required String id, required String status}) => {
      'id': id,
      'order_group_id': 'group-$id',
      'branch_id': 'branch-1',
      'receipt_number': 'RCP-$id',
      'grand_total': 21000,
      'order_status': status,
      'created_at': '2026-08-07 09:24:08',
      'updated_at': '2026-08-07 09:24:08',
      'items': <dynamic>[],
    };

/// Pumps [TenantOrderScreen] inside a minimal router, with the order board
/// backed by a fake repository seeded with 2 pending, 1 preparing, 1 ready
/// order (matching the old mock's Baru/Diproses/Selesai split) so the
/// existing sub-tab assertions stay meaningful.
Future<void> _pumpScreen(
  WidgetTester tester, {
  IncomingOrderStatus initialStatus = IncomingOrderStatus.baru,
}) async {
  final storage = FakeLocalStorage()..values[tenantBranchIdStorageKey] = 'branch-1';
  final dio = cannedDio(200, {
    'meta': {'success': true, 'message': 'Success', 'code': 200, 'trace_id': 'abc'},
    'data': [
      _orderJson(id: '1', status: 'PENDING'),
      _orderJson(id: '2', status: 'PENDING'),
      _orderJson(id: '3', status: 'PREPARING'),
      _orderJson(id: '4', status: 'READY'),
    ],
  });

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => TenantOrderScreen(initialStatus: initialStatus),
      ),
      GoRoute(
        path: '/ditolak',
        name: TenantRoutes.pesananDitolak,
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        tenantOrderRepositoryProvider.overrideWithValue(TenantOrderRepository(dio: dio)),
        tenantRealtimeServiceProvider.overrideWithValue(FakeTenantRealtimeService()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('TenantOrderScreen in-place status sub-filtering', () {
    testWidgets('starts on Order Baru and lists only baru orders', (tester) async {
      await _pumpScreen(tester);

      expect(find.byType(IncomingOrderCard), findsNWidgets(2));
      expect(find.text('Terima (29s)'), findsNWidgets(2));
      expect(find.text('Tolak'), findsNWidgets(2));
      expect(find.text('RCP-1'), findsOneWidget);
      expect(find.text('RCP-2'), findsOneWidget);
      expect(find.text('Siap Diambil'), findsNothing);
    });

    testWidgets('tapping Diproses switches the list in place', (tester) async {
      await _pumpScreen(tester);

      await tester.tap(find.text('Diproses'));
      await tester.pumpAndSettle();

      expect(find.byType(IncomingOrderCard), findsOneWidget);
      expect(find.text('Siap Diambil'), findsOneWidget);
      expect(find.text('Terima (29s)'), findsNothing);
    });

    testWidgets('tapping Selesai shows completed orders with no actions',
        (tester) async {
      await _pumpScreen(tester);

      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(find.byType(IncomingOrderCard), findsOneWidget);
      expect(find.text('Siap Diambil'), findsNothing);
      expect(find.text('Terima (29s)'), findsNothing);
      expect(find.text('Tolak'), findsNothing);
    });

    testWidgets('initialStatus seeds the diproses sub-tab (menu-diproses)',
        (tester) async {
      await _pumpScreen(tester, initialStatus: IncomingOrderStatus.diproses);

      expect(find.text('Siap Diambil'), findsOneWidget);
      expect(find.text('Terima (29s)'), findsNothing);
    });
  });
}

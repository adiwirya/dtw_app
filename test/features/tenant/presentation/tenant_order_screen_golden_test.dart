import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
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

/// Self-goldens for the tenant Order home in each sub-tab state
/// (`menu-order-baru` / `menu-diproses` / `selesai`).
///
/// NOTE: the headless harness loads Material + obra icons but not Open Sans, so
/// these goldens show the default family and CANNOT be pixel-diffed against the
/// Figma references (which are only available at half-res). They pin layout —
/// header band, tab bar + badges, card list, action rows — against
/// regressions; fidelity vs. the references was confirmed separately (see the
/// work-item report).
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

Future<void> _pump(
  WidgetTester tester,
  IncomingOrderStatus status,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

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
        builder: (context, state) =>
            TenantOrderScreen(initialStatus: status),
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
  testWidgets(
    'tenant order home — Order Baru',
    (tester) async {
      await _pump(tester, IncomingOrderStatus.baru);
      await expectLater(
        find.byType(TenantOrderScreen),
        matchesGoldenFile('goldens/tenant_order_baru.png'),
      );
    },
    tags: 'golden',
  );

  testWidgets(
    'tenant order home — Diproses',
    (tester) async {
      await _pump(tester, IncomingOrderStatus.diproses);
      await expectLater(
        find.byType(TenantOrderScreen),
        matchesGoldenFile('goldens/tenant_order_diproses.png'),
      );
    },
    tags: 'golden',
  );

  testWidgets(
    'tenant order home — Selesai',
    (tester) async {
      await _pump(tester, IncomingOrderStatus.selesai);
      await expectLater(
        find.byType(TenantOrderScreen),
        matchesGoldenFile('goldens/tenant_order_selesai.png'),
      );
    },
    tags: 'golden',
  );
}

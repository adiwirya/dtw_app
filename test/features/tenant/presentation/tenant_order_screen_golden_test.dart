import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_order_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Self-goldens for the tenant Order home in each sub-tab state
/// (`menu-order-baru` / `menu-diproses` / `selesai`).
///
/// NOTE: the headless harness loads Material + obra icons but not Open Sans, so
/// these goldens show the default family and CANNOT be pixel-diffed against the
/// Figma references (which are only available at half-res). They pin layout —
/// header band, tab bar + badges, card list, action rows — against
/// regressions; fidelity vs. the references was confirmed separately (see the
/// work-item report).
Future<void> _pump(
  WidgetTester tester,
  IncomingOrderStatus status,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

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

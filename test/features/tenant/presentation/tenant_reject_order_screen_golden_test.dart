import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_order_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_reject_order_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Self-goldens for the tenant reject screen in its two states
/// (`pesanan-ditolak`, all available / `konfirmasi-pesanan`, one item rejected).
///
/// NOTE: like the other tenant goldens, the harness loads Material + obra icons
/// but not Open Sans, so these show the default family and cannot be
/// pixel-diffed against the references — they pin layout against regressions.
/// Fidelity
/// vs. the references was confirmed separately (see the work-item report).
Future<void> _pump(WidgetTester tester, {required String? rejectedName}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => TenantRejectOrderScreen(
          initialRejectedName: rejectedName,
        ),
      ),
      GoRoute(
        path: '/diproses',
        name: TenantRoutes.pesananDiproses,
        builder: (context, state) => const TenantOrderScreen(
          initialStatus: IncomingOrderStatus.diproses,
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: router)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'reject screen — pesanan-ditolak (all available)',
    (tester) async {
      await _pump(tester, rejectedName: null);
      await expectLater(
        find.byType(TenantRejectOrderScreen),
        matchesGoldenFile('goldens/tenant_pesanan_ditolak.png'),
      );
    },
    tags: 'golden',
  );

  testWidgets(
    'reject screen — konfirmasi-pesanan (one item rejected)',
    (tester) async {
      await _pump(tester, rejectedName: 'Es Lemon Tea');
      await expectLater(
        find.byType(TenantRejectOrderScreen),
        matchesGoldenFile('goldens/tenant_konfirmasi_pesanan.png'),
      );
    },
    tags: 'golden',
  );
}

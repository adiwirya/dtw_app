import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_order_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Self-golden for the `menu-order-baru-2` order view (from a card tap).
/// It delegates to the Baru Order home; this golden pins that the route
/// target renders the board. See the reject-screen golden note about fonts.
void main() {
  testWidgets(
    'menu-order-baru-2 order detail (Baru board)',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const TenantOrderDetailScreen(),
          ),
          GoRoute(
            path: '/ditolak',
            name: TenantRoutes.pesananDitolak,
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/baru-2',
            name: TenantRoutes.orderDetail,
            builder: (context, state) => const SizedBox.shrink(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TenantOrderDetailScreen),
        matchesGoldenFile('goldens/tenant_order_baru_2.png'),
      );
    },
    tags: 'golden',
  );
}

import 'package:dtw_app/core/widgets/completed_detail_view.dart';
import 'package:dtw_app/core/widgets/order_card.dart';
import 'package:dtw_app/features/order/presentation/screens/order_screen.dart';
import 'package:dtw_app/features/order/presentation/screens/order_selesai_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Minimal router exercising the Order → Selesai → completed-order detail flow
/// so navigation targets can be asserted without the full app shell.
GoRouter _router() => GoRouter(
      initialLocation: '/order',
      routes: [
        GoRoute(
          path: '/order',
          name: 'order',
          builder: (_, _) => const OrderScreen(),
          routes: [
            GoRoute(
              path: 'selesai',
              name: 'orderSelesai',
              builder: (_, _) => const OrderScreen(),
              routes: [
                GoRoute(
                  path: 'detail',
                  name: 'orderSelesaiDetail',
                  builder: (_, _) => const OrderSelesaiDetailScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );

Widget _wrapScreen() {
  return const ProviderScope(
    child: MaterialApp(home: OrderSelesaiDetailScreen()),
  );
}

void main() {
  testWidgets('renders the key detail-selesai content', (tester) async {
    tester.view.physicalSize = const Size(390, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrapScreen());
    await tester.pumpAndSettle();

    expect(find.text('Detail Pesanan'), findsOneWidget);
    expect(find.text('#92842'), findsOneWidget);
    expect(find.text('Alur Tugas'), findsOneWidget);
    expect(find.text('Informasi Pesanan'), findsOneWidget);
    expect(find.text('Rincian item'), findsOneWidget);
    // Flow timeline steps.
    expect(find.text('Diambil'), findsOneWidget);
    expect(find.text('Diantar'), findsOneWidget);
    expect(find.text('Sampai Dimeja'), findsOneWidget);
    // Green grand total.
    expect(find.text('Rp40.000'), findsOneWidget);
    // detail-selesai shows the tenant name both as the card title and as the
    // "Tenan" info-row value.
    expect(find.text('KFC Fried Chicken'), findsNWidgets(2));
  });

  testWidgets('back button pops to the previous route', (tester) async {
    final router = _router();
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    // Drive directly to the detail route, then pop via the nav-bar back button.
    router.goNamed('orderSelesaiDetail');
    await tester.pumpAndSettle();
    expect(find.byType(OrderSelesaiDetailScreen), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.byType(OrderSelesaiDetailScreen), findsNothing);
    expect(find.byType(OrderScreen), findsOneWidget);
  });

  testWidgets('tapping a Selesai card opens the completed-order detail',
      (tester) async {
    tester.view.physicalSize = const Size(390, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pumpAndSettle();

    // Switch to the Selesai sub-tab in place.
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    // Tapping the completed-order card navigates to the real detail screen.
    await tester.tap(find.byType(OrderCard).first);
    await tester.pumpAndSettle();

    expect(find.byType(OrderSelesaiDetailScreen), findsOneWidget);
    expect(find.byType(CompletedDetailView), findsOneWidget);
    expect(find.text('Detail Pesanan'), findsOneWidget);
  });
}

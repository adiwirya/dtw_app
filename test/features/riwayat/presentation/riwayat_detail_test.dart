import 'package:dtw_app/core/widgets/completed_detail_view.dart';
import 'package:dtw_app/features/riwayat/presentation/screens/riwayat_detail_screen.dart';
import 'package:dtw_app/features/riwayat/presentation/screens/riwayat_screen.dart';
import 'package:dtw_app/features/riwayat/presentation/widgets/history_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Minimal router exercising the Riwayat → history-entry detail flow so
/// navigation targets can be asserted without the full app shell.
GoRouter _router() => GoRouter(
      initialLocation: '/riwayat',
      routes: [
        GoRoute(
          path: '/riwayat',
          name: 'riwayat',
          builder: (_, _) => const RiwayatScreen(),
          routes: [
            GoRoute(
              path: 'detail',
              name: 'riwayatDetail',
              builder: (_, _) => const RiwayatDetailScreen(),
            ),
          ],
        ),
      ],
    );

Widget _wrapScreen() {
  return const ProviderScope(
    child: MaterialApp(home: RiwayatDetailScreen()),
  );
}

void main() {
  testWidgets('renders the key detail-riwayat content', (tester) async {
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
    expect(find.text('Sampai Dimeja'), findsOneWidget);
    expect(find.text('Rp40.000'), findsOneWidget);
    // detail-riwayat's "Tenan" info-row value is the subtotal Rp35.000, which
    // also appears as the first line-item price.
    expect(find.text('Rp35.000'), findsNWidgets(2));
    // The tenant name appears once (card title only), unlike detail-selesai.
    expect(find.text('KFC Fried Chicken'), findsOneWidget);
  });

  testWidgets('back button pops to the previous route', (tester) async {
    final router = _router();
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    router.goNamed('riwayatDetail');
    await tester.pumpAndSettle();
    expect(find.byType(RiwayatDetailScreen), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.byType(RiwayatDetailScreen), findsNothing);
    expect(find.byType(RiwayatScreen), findsOneWidget);
  });

  testWidgets('a Riwayat row lands on the real detail screen, not a '
      'placeholder', (tester) async {
    tester.view.physicalSize = const Size(390, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pumpAndSettle();

    // Each history row exposes a "Detail" affordance that opens the detail.
    await tester.tap(find.byType(HistoryRow).first);
    await tester.pumpAndSettle();

    expect(find.byType(RiwayatDetailScreen), findsOneWidget);
    expect(find.byType(CompletedDetailView), findsOneWidget);
    expect(find.text('Detail Pesanan'), findsOneWidget);
  });
}

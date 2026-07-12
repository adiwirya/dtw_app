import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/widgets/app_toggle.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_order_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_reject_order_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Hosts the reject screen in a minimal router so `context.goNamed(...)`
/// targets (pesanan-diproses) resolve, and the modals can push/pop.
Future<GoRouter> _pump(WidgetTester tester, {Widget? screen}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            screen ?? const TenantRejectOrderScreen(),
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
  return router;
}

void main() {
  testWidgets('formatRupiah groups thousands with a dot', (_) async {
    expect(formatRupiah(35000), 'Rp35.000');
    expect(formatRupiah(5000), 'Rp5.000');
    expect(formatRupiah(1234567), 'Rp1.234.567');
    expect(formatRupiah(0), 'Rp0');
  });

  testWidgets('renders the order info, banner and per-item rows',
      (tester) async {
    await _pump(tester);

    expect(find.text('Tolak Pesanan'), findsOneWidget);
    expect(find.text('#92842'), findsOneWidget);
    expect(find.text('Anda dapat menolak sebagian item'), findsOneWidget);
    expect(find.text('Daftar Item'), findsOneWidget);
    expect(find.text('Paket Super Besar'), findsOneWidget);
    expect(find.text('Es Lemon Tea'), findsOneWidget);
    // Both items available → both show the Tersedia chip, total = 40.000.
    expect(find.text('Tersedia'), findsNWidgets(2));
    expect(find.text('2 item tersedia'), findsOneWidget);
    expect(find.text('Rp40.000'), findsOneWidget);
    expect(find.text('Konfirmasi Pesanan'), findsOneWidget);
  });

  testWidgets(
    'rejecting an item via the reason modal switches the row to rejected + '
    'updates the summary',
    (tester) async {
      await _pump(tester);

      // Toggle Es Lemon Tea (the second item) off → the reason sheet opens.
      await tester.tap(find.byType(AppToggle).at(1));
      await tester.pumpAndSettle();
      expect(find.text('Alasan Menolak Item'), findsOneWidget);

      // Pick a preset reason and save.
      await tester.tap(find.text('Stok Habis'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan Alasan'));
      await tester.pumpAndSettle();

      // The rejected row + confirmation banner + recomputed summary.
      expect(find.text('Tidak Tersedia'), findsOneWidget);
      expect(find.text('Alasan : '), findsOneWidget);
      expect(find.text('Stok Habis'), findsOneWidget);
      expect(find.text('1 item ditolak oleh tenant'), findsOneWidget);
      expect(find.text('1 dari 2 item tersedia'), findsOneWidget);
      // Accepted total drops to Paket Super Besar only.
      expect(find.text('Rp35.000'), findsWidgets);
    },
  );

  testWidgets('konfirmasi deep-link seeds the confirmed state', (tester) async {
    await _pump(
      tester,
      screen: const TenantRejectOrderScreen(
        initialRejectedName: 'Es Lemon Tea',
      ),
    );

    expect(find.text('Tidak Tersedia'), findsOneWidget);
    expect(find.text('Alasan : '), findsOneWidget);
    expect(find.text('Stok Habis'), findsOneWidget);
    expect(find.text('1 item ditolak oleh tenant'), findsOneWidget);
  });

  testWidgets('Konfirmasi Pesanan raises the success modal → Diproses',
      (tester) async {
    await _pump(
      tester,
      screen: const TenantRejectOrderScreen(
        initialRejectedName: 'Es Lemon Tea',
      ),
    );

    await tester.tap(find.text('Konfirmasi Pesanan'));
    await tester.pumpAndSettle();

    // The berhasil-ditambahkan-2 modal.
    expect(find.text('Pesanan dikonfirmasi'), findsOneWidget);
    expect(find.text('1 item diterima'), findsOneWidget);
    expect(find.text('1 item ditolak'), findsOneWidget);

    // Confirm → lands on the Diproses order home.
    await tester.tap(find.text('Konfirmasi Pesanan').last);
    await tester.pumpAndSettle();
    expect(find.byType(TenantOrderScreen), findsOneWidget);
  });
}

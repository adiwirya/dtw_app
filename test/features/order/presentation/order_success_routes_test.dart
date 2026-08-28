import 'package:dtw_app/app.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/widgets/success_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/busboy_board.dart';

const _deliveryId = 'delivery-1';

/// Boots the real app (so the real merged router is exercised, not a stand-in)
/// already signed in, then deep-links to [routeName] for [_deliveryId].
Future<void> _deepLink(
  WidgetTester tester,
  String routeName, {
  String orderId = _deliveryId,
  String status = 'PENDING_PICKUP',
}) async {
  tester.view.physicalSize = const Size(390, 950);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: busboyBoardOverrides(
      dio: cannedDeliveryListDio([
        deliveryJson(
          id: _deliveryId,
          status: status,
          tableNumber: 'B-07',
          customerName: 'Siti Aminah',
          deliveredAt: status == 'DELIVERED' ? '2026-08-27 10:45:00' : null,
          orders: [
            deliveryOrderJson(orderId: 'order-1', brandName: 'Solaria'),
          ],
        ),
      ]),
    ),
  );
  addTearDown(container.dispose);
  container.read(isLoggedInProvider.notifier).state = true;

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  await tester.pumpAndSettle();

  container
      .read(appRouterProvider)
      .goNamed(routeName, pathParameters: {'orderId': orderId});
  await tester.pumpAndSettle();
}

void main() {
  // These two routes used to render `PlaceholderScreen` — a stub page titled
  // "Berhasil Ditambahkan" with none of the frame's actual content.
  group('berhasil-ditambahkan (claimed)', () {
    testWidgets('raises the claim modal for the real delivery', (tester) async {
      await _deepLink(tester, AppRoutes.orderBerhasil);

      expect(find.byType(SuccessModal), findsOneWidget);
      expect(find.text('Tugas Berhasil Diambil!'), findsOneWidget);

      // Rows describe the delivery the id names, not a sample.
      final inModal = find.descendant(
        of: find.byType(SuccessModal),
        matching: find.text('Solaria'),
      );
      expect(inModal, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SuccessModal),
          matching: find.text('Siti Aminah'),
        ),
        findsOneWidget,
      );
      // No zone name on a busboy delivery, so no dangling dot separator.
      expect(
        find.descendant(
          of: find.byType(SuccessModal),
          matching: find.text('Meja B-07'),
        ),
        findsOneWidget,
      );
      expect(find.text('KFC Fried Chicken'), findsNothing);
    });

    testWidgets('confirming lands on the Order home', (tester) async {
      await _deepLink(tester, AppRoutes.orderBerhasil);

      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();

      expect(find.byType(SuccessModal), findsNothing);
      // Back on the Order home with its sub-tabs.
      expect(find.text('Ambil'), findsOneWidget);
    });
  });

  group('berhasil-ditambahkan-2 (delivered)', () {
    testWidgets('raises the delivered modal with its own copy',
        (tester) async {
      await _deepLink(
        tester,
        AppRoutes.orderSelesaiBerhasil,
        status: 'DELIVERED',
      );

      expect(find.byType(SuccessModal), findsOneWidget);
      expect(find.text('Pesanan telah berhasil diantar'), findsOneWidget);
      expect(find.text('Lanjutkan'), findsOneWidget);
      // Two rows here — the tenant is not repeated once delivered.
      expect(
        find.descendant(
          of: find.byType(SuccessModal),
          matching: find.text('Dari Tenant'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(SuccessModal),
          matching: find.text('Siti Aminah'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('confirming selects the Selesai sub-tab', (tester) async {
      await _deepLink(
        tester,
        AppRoutes.orderSelesaiBerhasil,
        status: 'DELIVERED',
      );

      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();

      expect(find.byType(SuccessModal), findsNothing);
      // The Selesai list shows the delivered-at footer.
      expect(find.text('Diantar pada'), findsOneWidget);
    });
  });

  // A deep link can arrive for anything. `SuccessModal.details` has no default
  // to fall back on, so an unknown id must surface as not-found rather than an
  // empty or fabricated modal.
  testWidgets('an unknown delivery id surfaces not-found, no modal',
      (tester) async {
    await _deepLink(tester, AppRoutes.orderBerhasil, orderId: 'ghost');

    expect(find.byType(SuccessModal), findsNothing);
    expect(
      find.text('Pesanan tidak ditemukan di daftar order.'),
      findsOneWidget,
    );
  });
}

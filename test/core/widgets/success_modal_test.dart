import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/core/widgets/success_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Detail rows owned by this test — `SuccessModal` has no default sample any
/// more, precisely so no caller can accidentally show one.
const _details = [
  SuccessModalDetail(
    icon: Icons.storefront_outlined,
    label: 'Dari Tenant',
    value: 'Solaria',
  ),
  SuccessModalDetail(
    icon: Icons.chair_outlined,
    label: 'Ke Meja',
    value: 'Meja B-07',
  ),
  SuccessModalDetail(
    icon: Icons.person_outline,
    label: 'Pelanggan',
    value: 'Siti Aminah',
  ),
];

/// Pumps a screen with a button that opens the modal via [showSuccessModal].
Widget _host({
  required VoidCallback onConfirm,
  String title = 'Tugas Berhasil Diambil!',
  String message = 'Silahkan antar pesanan ke meja tujuan',
  String confirmLabel = 'Mengerti',
  List<SuccessModalDetail> details = _details,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showSuccessModal(
              context,
              title: title,
              message: message,
              confirmLabel: confirmLabel,
              onConfirm: onConfirm,
              details: details,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('SuccessModal', () {
    testWidgets('shows the frame copy defaults and the caller-supplied rows',
        (tester) async {
      await tester.pumpWidget(_host(onConfirm: () {}));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(SuccessModal), findsOneWidget);
      // Title/message/CTA still default to the frame's copy — that is safe,
      // it describes the action, not the order.
      expect(find.text('Tugas Berhasil Diambil!'), findsOneWidget);
      expect(find.text('Silahkan antar pesanan ke meja tujuan'),
          findsOneWidget);
      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.text('Mengerti'), findsOneWidget);

      // The rows are whatever the caller passed — the widget has no sample of
      // its own to fall back to.
      expect(find.text('Dari Tenant'), findsOneWidget);
      expect(find.text('Solaria'), findsOneWidget);
      expect(find.text('Meja B-07'), findsOneWidget);
      expect(find.text('Siti Aminah'), findsOneWidget);
    });

    // Regression guard for the leak this API change closes: the old hardcoded
    // sample must not exist anywhere in the widget any more.
    testWidgets('has no built-in sample order to fall back to', (tester) async {
      await tester.pumpWidget(_host(onConfirm: () {}));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('KFC Fried Chicken'), findsNothing);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text('Meja A-12  •  Downtown'), findsNothing);
    });

    testWidgets('confirm button fires onConfirm', (tester) async {
      var confirms = 0;
      await tester.pumpWidget(_host(onConfirm: () => confirms++));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();
      expect(confirms, 1);
    });

    testWidgets('is dismissible by tapping the barrier', (tester) async {
      await tester.pumpWidget(_host(onConfirm: () {}));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(SuccessModal), findsOneWidget);

      // Tap the barrier (top-left, outside the centered card).
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(SuccessModal), findsNothing);
    });

    testWidgets('renders caller-supplied title/message/label/details',
        (tester) async {
      await tester.pumpWidget(
        _host(
          title: 'Sampai dimeja',
          message: 'Pesanan telah berhasil diantar',
          confirmLabel: 'Lanjutkan',
          onConfirm: () {},
          details: const [
            SuccessModalDetail(
              icon: Icons.chair_outlined,
              label: 'Ke Meja',
              value: 'Meja A-12  •  Downtown',
            ),
            SuccessModalDetail(
              icon: Icons.schedule,
              label: 'Waktu Sampai',
              value: '10:45 WIB  •  12 Mei 2024',
            ),
          ],
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Sampai dimeja'), findsOneWidget);
      expect(find.text('Pesanan telah berhasil diantar'), findsOneWidget);
      expect(find.text('Waktu Sampai'), findsOneWidget);
      expect(find.text('Lanjutkan'), findsOneWidget);
      // Only the rows this caller passed.
      expect(find.text('Dari Tenant'), findsNothing);
    });
  });
}

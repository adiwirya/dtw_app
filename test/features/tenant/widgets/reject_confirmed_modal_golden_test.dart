import 'package:dtw_app/features/tenant/presentation/widgets/reject_confirmed_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Self-golden for the `berhasil-ditambahkan-2` rejection confirmation modal.
/// Layout-pinning golden; see the reject-screen golden note about fonts.
void main() {
  testWidgets(
    'berhasil-ditambahkan-2 confirmation modal',
    (tester) async {
      tester.view.physicalSize = const Size(390, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RejectConfirmedModal(
                acceptedCount: 1,
                rejectedCount: 1,
                acceptedTotal: 'Rp35.000',
                onConfirm: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(RejectConfirmedModal),
        matchesGoldenFile('goldens/tenant_pesanan_berhasil.png'),
      );
    },
    tags: 'golden',
  );
}

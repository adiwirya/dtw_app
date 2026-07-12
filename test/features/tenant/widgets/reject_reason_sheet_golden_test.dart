import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/reject_reason_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Self-golden for the `alasan-penolakan` reason modal. Layout-pinning golden;
/// see the reject-screen golden note about fonts.
void main() {
  testWidgets(
    'alasan-penolakan reason sheet',
    (tester) async {
      tester.view.physicalSize = const Size(390, 520);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: RejectReasonSheet(
                item: OrderLineItem(name: 'Es Lemon Tea', price: 'Rp5.000'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(RejectReasonSheet),
        matchesGoldenFile('goldens/tenant_alasan_penolakan.png'),
      );
    },
    tags: 'golden',
  );
}

import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/reject_reason_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _item = OrderLineItem(qty: 2, name: 'Es Kopi Susu', price: 'Rp36.000');

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: RejectReasonSheet(item: _item))),
  );
}

void main() {
  testWidgets('Simpan Alasan is disabled until a reason is chosen', (
    tester,
  ) async {
    await _pump(tester);

    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('selecting a preset reason enables Simpan Alasan', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Stok Habis'));
    await tester.pump();

    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('Simpan Alasan pops with the selected preset title', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showRejectReasonSheet(context, item: _item);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bahan tidak tersedia'));
    await tester.pump();
    await tester.tap(find.text('Simpan Alasan'));
    await tester.pumpAndSettle();

    expect(result, 'Bahan tidak tersedia');
  });

  testWidgets(
    'typing a custom reason overrides the selected preset',
    (tester) async {
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showRejectReasonSheet(context, item: _item);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stok Habis'));
      await tester.pump();
      await tester.enterText(
        find.byType(TextField),
        'Alasan custom dari tenant',
      );
      await tester.pump();
      await tester.tap(find.text('Simpan Alasan'));
      await tester.pumpAndSettle();

      expect(result, 'Alasan custom dari tenant');
    },
  );

  testWidgets('the close icon pops with null (dismissed, no reason)', (
    tester,
  ) async {
    String? result = 'unset';
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showRejectReasonSheet(context, item: _item);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}

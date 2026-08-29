import 'package:dtw_app/features/tenant/presentation/screens/tambah_varian_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/opsi_varian_modal.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/variant_rows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(debugShowCheckedModeBanner: false, home: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('OpsiVarianModal (option add form)', () {
    testWidgets('renders the L6 fields and the Rp +price add-on',
        (tester) async {
      await _pump(tester, const OpsiVarianModal());
      expect(find.text('Opsi & Customisasi'), findsOneWidget);
      expect(find.text('Nama Opsi'), findsOneWidget);
      expect(find.text('Harga'), findsOneWidget);
      expect(find.text('(Optional)'), findsOneWidget);
      expect(find.text('Rp'), findsOneWidget); // the "+price" add-on box
      expect(find.text('Simpan'), findsOneWidget);
    });

    testWidgets('Simpan emits a priced option (RpN.NNN)', (tester) async {
      VariantOptionData? saved;
      await _pump(
        tester,
        OpsiVarianModal(
          initialName: 'Medium',
          initialPrice: '3000',
          onSave: (o) => saved = o,
        ),
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      expect(saved!.name, 'Medium');
      expect(saved!.isFree, isFalse);
      expect(saved!.addonPrice, 'Rp3.000');
    });

    testWidgets('Simpan with zero price emits a free option', (tester) async {
      VariantOptionData? saved;
      await _pump(
        tester,
        OpsiVarianModal(
          initialName: 'Small',
          initialPrice: '0',
          onSave: (o) => saved = o,
        ),
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(saved!.name, 'Small');
      expect(saved!.isFree, isTrue); // rendered as "Gratis"
    });
  });

  group('TambahVarianScreen with options (tambah-opsi-2 / opsi-2-ditambahkan)',
      () {
    testWidgets('renders the option rows, reorder caption and Simpan Varian',
        (tester) async {
      await _pump(
        tester,
        TambahVarianScreen(
          prefilled: true,
          options: const [
            VariantOptionData(name: 'Small'),
            VariantOptionData(name: 'Medium', addonPrice: 'Rp3.000'),
          ],
          onSave: () {},
        ),
      );
      expect(find.byType(VariantOptionRow), findsNWidgets(2));
      expect(find.text('Small'), findsOneWidget);
      expect(find.text('Gratis'), findsOneWidget);
      expect(find.text('+Rp3.000'), findsOneWidget);
      expect(find.text('Geser untuk mengubah urutan opsi'), findsOneWidget);
      expect(find.text('Simpan Varian'), findsOneWidget);
      expect(find.text('Belum ada opsi'), findsNothing);
    });

    // The caption "Geser untuk mengubah urutan opsi" and the drag handle were
    // decorative — no ReorderableListView, no onReorder anywhere.
    testWidgets('the option rows are reorderable', (tester) async {
      await _pump(
        tester,
        TambahVarianScreen(
          prefilled: true,
          options: const [
            VariantOptionData(name: 'Small'),
            VariantOptionData(name: 'Medium', addonPrice: 'Rp3.000'),
            VariantOptionData(name: 'Large', addonPrice: 'Rp5.000'),
          ],
          onSave: () {},
        ),
      );

      expect(find.byType(ReorderableListView), findsOneWidget);
      // Each row's handle drives the drag, not a default handle on the side.
      expect(
        find.byType(ReorderableDragStartListener),
        findsNWidgets(3),
      );
    });

    testWidgets('dragging a row moves it', (tester) async {
      await _pump(
        tester,
        TambahVarianScreen(
          prefilled: true,
          options: const [
            VariantOptionData(name: 'Small'),
            VariantOptionData(name: 'Medium', addonPrice: 'Rp3.000'),
          ],
          onSave: () {},
        ),
      );

      List<String> order() => tester
          .widgetList<VariantOptionRow>(find.byType(VariantOptionRow))
          .map((r) => r.data.name)
          .toList();
      expect(order(), ['Small', 'Medium']);

      // `ReorderableDragStartListener` starts the drag on pointer-down, and
      // the list needs incremental moves to track it.
      final handle = find.byType(ReorderableDragStartListener).first;
      final drag = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 50));
      for (var i = 0; i < 4; i++) {
        await drag.moveBy(const Offset(0, 25));
        await tester.pump(const Duration(milliseconds: 20));
      }
      await drag.up();
      await tester.pumpAndSettle();

      expect(order(), ['Medium', 'Small']);
    });

    testWidgets('removing an option drops its row', (tester) async {
      await _pump(
        tester,
        TambahVarianScreen(
          prefilled: true,
          options: const [VariantOptionData(name: 'Small')],
          onSave: () {},
        ),
      );
      expect(find.byType(VariantOptionRow), findsOneWidget);
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();
      expect(find.byType(VariantOptionRow), findsNothing);
    });

    testWidgets(
        'empty form keeps the "Belum ada opsi" placeholder; Simpan Varian '
        'always shows (it is the real save action now)', (tester) async {
      await _pump(tester, const TambahVarianScreen());
      expect(find.text('Belum ada opsi'), findsOneWidget);
      expect(find.byType(VariantOptionRow), findsNothing);
      expect(find.text('Simpan Varian'), findsOneWidget);
    });
  });
}

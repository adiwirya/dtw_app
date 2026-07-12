import 'package:dtw_app/features/tenant/presentation/providers/variant_provider.dart';
import 'package:dtw_app/features/tenant/presentation/screens/kelola_varian_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/pilih_varian_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tambah_menu_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tambah_varian_screen.dart';
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
  group('VariantList notifier (mock)', () {
    test('starts empty, add appends, loadSaved seeds savedVariants', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(variantListProvider), isEmpty);

      container.read(variantListProvider.notifier).add(
            const VariantData(
              name: 'Tingkat Pedas',
              type: VariantType.tunggal,
              options: [VariantOptionData(name: 'Original')],
            ),
          );
      expect(container.read(variantListProvider), hasLength(1));

      container.read(variantListProvider.notifier).loadSaved();
      expect(container.read(variantListProvider), savedVariants);
    });

    test('savedVariants model the L6 rules and +price options', () {
      final pedas = savedVariants.first;
      expect(pedas.isRequired, isTrue); // Wajib Dipilih
      expect(pedas.multiSelect, isFalse);

      final topping =
          savedVariants.firstWhere((v) => v.name == 'Extra Topping');
      expect(topping.multiSelect, isTrue); // Pilih Lebih dari Satu
      // L6: options carry a "+price" add-on.
      expect(topping.options.any((o) => o.addonPrice != null), isTrue);
    });
  });

  group('KelolaVarianScreen', () {
    testWidgets('empty state shows placeholder + Buat Varian', (tester) async {
      await _pump(tester, const KelolaVarianScreen());
      expect(find.text('Varian Saya'), findsOneWidget);
      expect(find.text('Belum ada Varian Menu'), findsOneWidget);
      expect(find.text('Buat Varian'), findsOneWidget);
    });

    testWidgets('saved state lists variants with usage footer',
        (tester) async {
      await _pump(tester, const KelolaVarianScreen(saved: true));
      expect(find.text('Tingkat Pedas'), findsOneWidget);
      expect(find.text('Ukuran Minuman'), findsOneWidget);
      expect(find.text('Extra Topping'), findsOneWidget);
      expect(find.text('Digunakan di 12 menu'), findsOneWidget);
      expect(find.text('Buat Varian'), findsNothing);
    });
  });

  group('PilihVarianScreen (picker)', () {
    testWidgets('renders rows and seeded selection count', (tester) async {
      await _pump(tester, const PilihVarianScreen());
      expect(find.text('Pilih Varian'), findsOneWidget);
      expect(find.byType(VariantSelectRow), findsNWidgets(3));
      expect(find.text('2 Varian Dipilih'), findsOneWidget);
    });

    testWidgets('tapping a row updates the selection count', (tester) async {
      await _pump(tester, const PilihVarianScreen());
      // Third row starts unselected -> tapping it makes it 3 selected.
      await tester.tap(find.text('Extra Topping'));
      await tester.pumpAndSettle();
      expect(find.text('3 Varian Dipilih'), findsOneWidget);
    });
  });

  group('TambahVarianScreen (form)', () {
    testWidgets('empty form shows name, both L6 rule toggles, opsi',
        (tester) async {
      await _pump(tester, const TambahVarianScreen());
      expect(find.text('Nama Varian'), findsOneWidget);
      expect(find.text('Wajib Dipilih'), findsOneWidget);
      expect(find.text('Pilih Lebih dari Satu'), findsOneWidget);
      expect(find.byType(VariantRuleToggleRow), findsNWidgets(2));
      expect(find.text('Belum ada opsi'), findsOneWidget);
      expect(find.text('Tambah Opsi'), findsOneWidget);
    });

    testWidgets('prefilled form seeds the variant name', (tester) async {
      await _pump(tester, const TambahVarianScreen(prefilled: true));
      expect(find.text('Ukuran Minuman'), findsOneWidget);
    });
  });

  group('TambahMenuScreen with attached variants (varian-ditambahkan)', () {
    testWidgets('shows the variant count and attached rows', (tester) async {
      await _pump(
        tester,
        const TambahMenuScreen(
          prefilled: true,
          variants: attachedMenuVariants,
        ),
      );
      expect(find.text('(2)'), findsOneWidget);
      expect(find.text('Level Kepedasan'), findsOneWidget);
      expect(find.text('Ukuran Size'), findsOneWidget);
    });
  });
}

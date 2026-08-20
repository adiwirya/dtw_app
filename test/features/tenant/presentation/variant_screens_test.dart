import 'package:dtw_app/features/tenant/data/models/tenant_branch.dart';
import 'package:dtw_app/features/tenant/data/repositories/modifier_group_repository.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
import 'package:dtw_app/features/tenant/presentation/providers/variant_provider.dart';
import 'package:dtw_app/features/tenant/presentation/screens/kelola_varian_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/pilih_varian_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tambah_menu_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tambah_varian_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/variant_rows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/canned_dio.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(debugShowCheckedModeBanner: false, home: child),
    ),
  );
  await tester.pumpAndSettle();
}

/// `KelolaVarianScreen` fetches the real variant list — seed a branch so it
/// resolves instead of hanging on the real (unmocked) session-storage read.
/// [groups] are the raw `GET /v1/modifier-groups` item JSON.
List<Override> _kelolaVarianOverrides(List<Map<String, dynamic>> groups) {
  final branch = TenantBranch(
    id: 'branch-1',
    brandId: 'brand-1',
    brandName: 'Janji Jiwa',
    branchName: 'Janji Jiwa',
    areaName: 'Downtown',
    isActive: true,
    createdAt: DateTime(2026, 8, 7),
  );
  return [
    currentTenantBranchProvider.overrideWith((ref) async => branch),
    modifierGroupRepositoryProvider.overrideWithValue(
      ModifierGroupRepository(
        dio: cannedDio(200, {
          'meta': {
            'success': true,
            'message': 'Success',
            'code': 200,
            'trace_id': 'abc',
          },
          'data': groups,
        }),
      ),
    ),
  ];
}

void main() {
  test('savedVariants model the L6 rules and +price options', () {
    final pedas = savedVariants.first;
    expect(pedas.isRequired, isTrue); // Wajib Dipilih
    expect(pedas.multiSelect, isFalse);

    final topping = savedVariants.firstWhere((v) => v.name == 'Extra Topping');
    expect(topping.multiSelect, isTrue); // Pilih Lebih dari Satu
    // L6: options carry a "+price" add-on.
    expect(topping.options!.any((o) => o.addonPrice != null), isTrue);
  });

  group('KelolaVarianScreen', () {
    testWidgets('empty state shows placeholder + Buat Varian', (tester) async {
      await _pump(
        tester,
        const KelolaVarianScreen(),
        overrides: _kelolaVarianOverrides([]),
      );
      expect(find.text('Varian Saya'), findsOneWidget);
      expect(find.text('Belum ada Varian Menu'), findsOneWidget);
      expect(find.text('Buat Varian'), findsOneWidget);
    });

    testWidgets('non-empty state lists variants, no usage footer (no API '
        'source for it)', (tester) async {
      await _pump(
        tester,
        const KelolaVarianScreen(),
        overrides: _kelolaVarianOverrides([
          {
            'id': 'group-1',
            'brand_id': 'brand-1',
            'brand_name': 'Janji Jiwa',
            'name': 'Tingkat Pedas',
            'description': null,
            'is_required': true,
            'min_selections': 1,
            'max_selections': 1,
            'sequence_order': 1,
            'is_active': true,
            'option_count': 2,
            'created_at': '2026-08-13 11:01:33',
            'updated_at': '2026-08-13 11:01:33',
          },
        ]),
      );
      expect(find.text('Tingkat Pedas'), findsOneWidget);
      expect(find.text('2 Opsi'), findsOneWidget);
      expect(find.textContaining('Digunakan di'), findsNothing);
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

    testWidgets(
        'editing loads the real group: name/options shown, already-saved '
        'option has no remove button', (tester) async {
      final dio = cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Success',
          'code': 200,
          'trace_id': 'abc',
        },
        'data': {
          'id': 'group-1',
          'brand_id': 'brand-1',
          'brand_name': 'Janji Jiwa',
          'name': 'Ukuran Minuman',
          'description': null,
          'is_required': true,
          'min_selections': 1,
          'max_selections': 1,
          'sequence_order': 1,
          'is_active': true,
          'option_count': 1,
          'created_at': '2026-08-13 11:01:33',
          'updated_at': '2026-08-13 11:01:33',
          'options': [
            {
              'id': 'option-1',
              'modifier_group_id': 'group-1',
              'name': 'Small',
              'dpp_price': 0,
              'pb1_percentage': 11,
              'pb1_price': 0,
              'total_price': 0,
              'sequence_order': 1,
              'created_at': '2026-08-13 11:01:34',
              'updated_at': '2026-08-13 11:01:34',
            },
          ],
        },
      });
      await _pump(
        tester,
        const TambahVarianScreen(editingVariantId: 'group-1'),
        overrides: [
          modifierGroupRepositoryProvider.overrideWithValue(
            ModifierGroupRepository(dio: dio),
          ),
        ],
      );

      expect(find.text('Ukuran Minuman'), findsOneWidget);
      expect(find.text('Small'), findsOneWidget);
      // The one option is already saved (has an id) -> no remove button.
      expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
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

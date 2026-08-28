import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
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

/// One `GET /v1/modifier-groups` list item. `maxSelections > 1` is what the
/// app derives `VariantType.ganda` from, and the list endpoint deliberately
/// carries no `options` — only `option_count`.
Map<String, dynamic> _group(
  String id,
  String name, {
  int maxSelections = 1,
  int optionCount = 2,
}) => {
  'id': id,
  'brand_id': 'brand-1',
  'brand_name': 'Janji Jiwa',
  'name': name,
  'description': null,
  'is_required': true,
  'min_selections': 1,
  'max_selections': maxSelections,
  'sequence_order': 1,
  'is_active': true,
  'option_count': optionCount,
  'created_at': '2026-08-13 11:01:33',
  'updated_at': '2026-08-13 11:01:33',
};

/// `KelolaVarianScreen` and `PilihVarianScreen` both fetch the real variant
/// list — seed a branch so it resolves instead of hanging on the real
/// (unmocked) session-storage read. [groups] are the raw
/// `GET /v1/modifier-groups` item JSON.
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
    /// Taps a filter pill by label.
    ///
    /// The pills live in a horizontal `ListView`, and the headless harness
    /// renders text as full-em Ahem boxes — wide enough that the trailing
    /// pills sit outside the 390px design width. Scroll it into view first or
    /// `tap` derives an offset outside the render tree and silently misses.
    Future<void> tapPill(WidgetTester tester, String label) async {
      final pill = find.text(label);
      await tester.ensureVisible(pill);
      await tester.pumpAndSettle();
      await tester.tap(pill);
      await tester.pumpAndSettle();
    }

    List<Override> pickerOverrides() => _kelolaVarianOverrides([
      _group('group-1', 'Tingkat Pedas'),
      _group('group-2', 'Ukuran Minuman'),
      _group('group-3', 'Extra Topping', maxSelections: 3, optionCount: 5),
    ]);

    // The picker used to render a hardcoded `savedVariants` const with two
    // rows pre-ticked. It now reads the same real `GET /v1/modifier-groups`
    // list `KelolaVarianScreen` uses, and starts with nothing selected.
    testWidgets('renders the real variant list, nothing preselected',
        (tester) async {
      await _pump(
        tester,
        const PilihVarianScreen(),
        overrides: pickerOverrides(),
      );

      expect(find.text('Pilih Varian'), findsOneWidget);
      expect(find.byType(VariantSelectRow), findsNWidgets(3));
      expect(find.text('Tingkat Pedas'), findsOneWidget);
      expect(find.text('0 Varian Dipilih'), findsOneWidget);
    });

    testWidgets('Tambah is disabled until something is selected',
        (tester) async {
      await _pump(
        tester,
        const PilihVarianScreen(),
        overrides: pickerOverrides(),
      );

      PrimaryButton button() => tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'Tambah'),
      );
      expect(button().onPressed, isNull);

      await tester.tap(find.text('Extra Topping'));
      await tester.pumpAndSettle();

      expect(find.text('1 Varian Dipilih'), findsOneWidget);
      expect(button().onPressed, isNotNull);
    });

    testWidgets('selection survives filtering (keyed by id, not row index)',
        (tester) async {
      await _pump(
        tester,
        const PilihVarianScreen(),
        overrides: pickerOverrides(),
      );

      // Select the only Ganda variant, then filter it out and back in.
      await tester.tap(find.text('Extra Topping'));
      await tester.pumpAndSettle();
      expect(find.text('1 Varian Dipilih'), findsOneWidget);

      await tapPill(tester, 'Tunggal (2)');
      expect(find.byType(VariantSelectRow), findsNWidgets(2));
      expect(find.text('Extra Topping'), findsNothing);
      // Still counted even though its row is filtered away.
      expect(find.text('1 Varian Dipilih'), findsOneWidget);

      await tapPill(tester, 'Ganda (1)');
      expect(find.byType(VariantSelectRow), findsOneWidget);
      expect(find.text('Extra Topping'), findsOneWidget);
    });

    testWidgets('search filters by name and reports no match', (tester) async {
      await _pump(
        tester,
        const PilihVarianScreen(),
        overrides: pickerOverrides(),
      );

      await tester.enterText(find.byType(AppInput), 'ukuran');
      await tester.pumpAndSettle();
      expect(find.byType(VariantSelectRow), findsOneWidget);
      expect(find.text('Ukuran Minuman'), findsOneWidget);

      await tester.enterText(find.byType(AppInput), 'zzz');
      await tester.pumpAndSettle();
      expect(find.byType(VariantSelectRow), findsNothing);
      expect(find.text('Varian tidak ditemukan.'), findsOneWidget);
    });

    // `GET /v1/modifier-groups` returns option_count without the option
    // names, so the preview line must be omitted rather than render blank.
    testWidgets('shows the option count but no name preview from the list '
        'endpoint', (tester) async {
      await _pump(
        tester,
        const PilihVarianScreen(),
        overrides: pickerOverrides(),
      );

      expect(find.text('2 Opsi'), findsNWidgets(2));
      expect(find.text('5 Opsi'), findsOneWidget);
      expect(find.text('Original, Spicy'), findsNothing);
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

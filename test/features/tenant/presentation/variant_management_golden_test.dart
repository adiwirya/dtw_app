import 'package:dtw_app/features/tenant/data/models/tenant_branch.dart';
import 'package:dtw_app/features/tenant/data/repositories/modifier_group_repository.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
import 'package:dtw_app/features/tenant/presentation/providers/variant_provider.dart';
import 'package:dtw_app/features/tenant/presentation/screens/kelola_varian_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/pilih_varian_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tambah_menu_screen.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tambah_varian_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/canned_dio.dart';

/// Self-goldens for the tenant variant-management screens (Part A).
///
/// NOTE: like the other tenant self-goldens, the headless harness renders text
/// as Ahem boxes (Open Sans is not bundled), so these pin layout/structure/
/// colours against regressions rather than pixel-diffing the Figma references;
/// fidelity vs. each `.ftk/figma/.../reference.png` was confirmed separately
/// during the build (see the work-item report).
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required Size size,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = size;
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

/// `KelolaVarianScreen` fetches the real variant list — seed a branch + a
/// canned `GET /v1/modifier-groups` response ([groups]) so it resolves
/// instead of hanging on the real (unmocked) session-storage read.
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

Map<String, dynamic> _group(String id, String name) => {
      'id': id,
      'brand_id': 'brand-1',
      'brand_name': 'Janji Jiwa',
      'name': name,
      'description': null,
      'is_required': true,
      'min_selections': 1,
      'max_selections': 1,
      'sequence_order': 1,
      'is_active': true,
      'option_count': 2,
      'created_at': '2026-08-13 11:01:33',
      'updated_at': '2026-08-13 11:01:33',
    };

void main() {
  group('variant management goldens', () {
    testWidgets('kelola-varian (empty)', (tester) async {
      await _pump(
        tester,
        const KelolaVarianScreen(),
        size: const Size(390, 844),
        overrides: _kelolaVarianOverrides([]),
      );
      await expectLater(
        find.byType(KelolaVarianScreen),
        matchesGoldenFile('goldens/kelola_varian.png'),
      );
    }, tags: 'golden');

    testWidgets('varian-disimpan (saved list)', (tester) async {
      await _pump(
        tester,
        const KelolaVarianScreen(),
        size: const Size(390, 844),
        overrides: _kelolaVarianOverrides([
          _group('group-1', 'Tingkat Pedas'),
          _group('group-2', 'Ukuran Minuman'),
          _group('group-3', 'Extra Topping'),
        ]),
      );
      await expectLater(
        find.byType(KelolaVarianScreen),
        matchesGoldenFile('goldens/varian_disimpan.png'),
      );
    }, tags: 'golden');

    testWidgets('tambah-varian (Pilih Varian picker)', (tester) async {
      await _pump(tester, const PilihVarianScreen(),
          size: const Size(390, 844));
      await expectLater(
        find.byType(PilihVarianScreen),
        matchesGoldenFile('goldens/tambah_varian.png'),
      );
    }, tags: 'golden');

    testWidgets('tambah-varian-2 (empty form)', (tester) async {
      await _pump(tester, const TambahVarianScreen(),
          size: const Size(390, 844));
      await expectLater(
        find.byType(TambahVarianScreen),
        matchesGoldenFile('goldens/tambah_varian_2.png'),
      );
    }, tags: 'golden');

    testWidgets('varian-diisi (filled form)', (tester) async {
      await _pump(tester, const TambahVarianScreen(prefilled: true),
          size: const Size(390, 844));
      await expectLater(
        find.byType(TambahVarianScreen),
        matchesGoldenFile('goldens/varian_diisi.png'),
      );
    }, tags: 'golden');

    testWidgets('varian-ditambahkan (menu form w/ variants)', (tester) async {
      await _pump(
        tester,
        const TambahMenuScreen(
          prefilled: true,
          variants: attachedMenuVariants,
        ),
        size: const Size(390, 1480),
      );
      await expectLater(
        find.byType(TambahMenuScreen),
        matchesGoldenFile('goldens/varian_ditambahkan.png'),
      );
    }, tags: 'golden');
  });
}

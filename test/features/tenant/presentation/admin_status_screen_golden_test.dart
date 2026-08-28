import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_branch_repository.dart';
import 'package:dtw_app/features/tenant/presentation/screens/admin_status_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/canned_dio.dart';
import '../../../support/tenant_board.dart';

/// Self-goldens for the Admin status screen (`admin-offline` / `admin-online`
/// — both routes render the same `AdminStatusScreen`; the online/offline
/// distinction was removed, see `AdminHeroHeader`/`tenant_router.dart`).
///
/// NOTE: the headless harness does not load Open Sans (the cache font), so the
/// goldens show placeholder text glyphs and CANNOT be pixel-diffed against the
/// Figma `reference.png`. The Obra icon font IS loaded (see
/// `flutter_test_config.dart`). These goldens pin layout (structure, spacing,
/// colours, hero + card placement) against regressions; fidelity vs. the two
/// references was confirmed separately by rendering and comparing screenshots
/// (see the work-item report).
void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final dio = cannedDio(
      200,
      tenantEnvelope({
        'id': testBranchId,
        'brand_id': 'brand-1',
        'brand_name': 'Janji Jiwa',
        'branch_name': 'KFC Fried Chicken',
        'area_name': 'Downtown',
        'is_active': true,
        'created_at': '2024-04-24 10:00:00',
      }),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(branchScopedStorage()),
          tenantBranchRepositoryProvider.overrideWithValue(
            TenantBranchRepository(dio: dio),
          ),
        ],
        child: const MaterialApp(home: AdminStatusScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'admin-offline self-golden',
    (tester) async {
      await pumpScreen(tester);
      await expectLater(
        find.byType(AdminStatusScreen),
        matchesGoldenFile('goldens/admin_offline.png'),
      );
    },
    tags: 'golden',
  );

  testWidgets(
    'admin-online self-golden (same screen as admin-offline, route stays '
    'for frame-route stability)',
    (tester) async {
      await pumpScreen(tester);
      await expectLater(
        find.byType(AdminStatusScreen),
        matchesGoldenFile('goldens/admin_online.png'),
      );
    },
    tags: 'golden',
  );
}

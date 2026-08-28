import 'package:dio/dio.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_branch_repository.dart';
import 'package:dtw_app/features/tenant/presentation/screens/admin_status_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/canned_dio.dart';
import '../../../support/tenant_board.dart';

Widget _host({required Dio dio}) => ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(branchScopedStorage()),
        tenantBranchRepositoryProvider.overrideWithValue(
          TenantBranchRepository(dio: dio),
        ),
      ],
      child: const MaterialApp(home: AdminStatusScreen()),
    );

Dio _cannedBranch({required bool isActive}) => cannedDio(
      200,
      tenantEnvelope({
        'id': testBranchId,
        'brand_id': 'brand-1',
        'brand_name': 'Janji Jiwa',
        'branch_name': 'Janji Jiwa',
        'area_name': 'Downtown',
        'is_active': isActive,
        'created_at': '2026-08-07 09:16:37',
      }),
    );

void main() {
  group('AdminStatusScreen', () {
    testWidgets(
        'renders the real tenant name and joined date from '
        'GET /v1/tenant-branches/{id}', (tester) async {
      await tester.pumpWidget(_host(dio: _cannedBranch(isActive: false)));
      await tester.pumpAndSettle();

      expect(find.text('Janji Jiwa'), findsOneWidget);
      expect(find.text('Bergabung Sejak'), findsOneWidget);
      expect(find.text('7 Agustus 2026'), findsOneWidget);
    });

    // The API has no booth/location, rating, contact or operating-hours
    // fields yet (confirmed live — see `TenantBranch`) — the screen must hide
    // those rows rather than show fabricated placeholder data.
    testWidgets(
        'hides booth, rating, contact and Jam Operasional — the API has no '
        'data for them yet', (tester) async {
      await tester.pumpWidget(_host(dio: _cannedBranch(isActive: false)));
      await tester.pumpAndSettle();

      expect(find.text('Jam Operasional'), findsNothing);
      expect(find.text('Rating'), findsNothing);
      expect(find.text('Contact Tenant'), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing); // hero rating chip
    });

    testWidgets('shows the mapped error message when the fetch fails',
        (tester) async {
      await tester.pumpWidget(
        _host(
          dio: cannedDio(500, {
            'meta': {
              'success': false,
              'message': 'Server error',
              'code': 500,
              'trace_id': 'abc',
            },
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });
  });
}

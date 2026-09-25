import 'package:dtw_app/features/tenant/data/models/tenant_branch.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_branch_repository.dart';
import 'package:dtw_app/features/tenant/presentation/providers/admin_status_provider.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/canned_dio.dart';

TenantBranch _testBranch() => TenantBranch(
      id: 'branch-1',
      brandId: 'brand-1',
      brandName: 'Janji Jiwa',
      branchName: 'Janji Jiwa Summarecon',
      areaName: 'Downtown',
      locationCode: 'SMB',
      isActive: true,
      createdAt: DateTime(2026, 8, 7),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('combines the branch info with the fetched brand logo', () async {
    final dio = cannedDio(200, {
      'meta': {
        'success': true,
        'message': 'Success',
        'code': 200,
        'trace_id': 'abc',
      },
      'data': {'id': 'brand-1', 'logo_url': 'https://cdn/logo.png'},
    });
    final container = ProviderContainer(
      overrides: [
        currentTenantBranchProvider.overrideWith((ref) async => _testBranch()),
        tenantBranchRepositoryProvider.overrideWithValue(
          TenantBranchRepository(dio: dio),
        ),
      ],
    );
    addTearDown(container.dispose);

    final info = await container.read(tenantAdminInfoProvider.future);

    expect(info.name, 'Janji Jiwa Summarecon');
    expect(info.logoUrl, 'https://cdn/logo.png');
  });

  test(
    'degrades to a null logo when the brand-logo fetch fails — a display '
    'nicety, not core profile data',
    () async {
      final dio = cannedDio(500, {
        'meta': {
          'success': false,
          'message': 'Error',
          'code': 500,
          'trace_id': 'abc',
        },
      });
      final container = ProviderContainer(
        overrides: [
          currentTenantBranchProvider.overrideWith(
            (ref) async => _testBranch(),
          ),
          tenantBranchRepositoryProvider.overrideWithValue(
            TenantBranchRepository(dio: dio),
          ),
        ],
      );
      addTearDown(container.dispose);

      final info = await container.read(tenantAdminInfoProvider.future);

      expect(info.name, 'Janji Jiwa Summarecon');
      expect(info.logoUrl, isNull);
    },
  );
}

import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_branch_repository.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/canned_dio.dart';
import '../../../support/fake_local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fetches the branch for the stored tenantBranchIdStorageKey', () async {
    final storage = FakeLocalStorage()
      ..values[tenantBranchIdStorageKey] = 'branch-1';
    final dio = cannedDio(200, {
      'meta': {
        'success': true,
        'message': 'Success',
        'code': 200,
        'trace_id': 'abc',
      },
      'data': {
        'id': 'branch-1',
        'brand_id': 'brand-1',
        'brand_name': 'Janji Jiwa',
        'branch_name': 'Janji Jiwa Summarecon',
        'area_name': 'Downtown',
        'kd_lokasi': 'SMB',
        'is_active': true,
        'created_at': '2026-08-07 09:16:59',
      },
    });
    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        tenantBranchRepositoryProvider.overrideWithValue(
          TenantBranchRepository(dio: dio),
        ),
      ],
    );
    addTearDown(container.dispose);

    final branch = await container.read(currentTenantBranchProvider.future);

    expect(branch.id, 'branch-1');
    expect(
      (dio.httpClientAdapter as CannedAdapter).lastRequest!.path,
      '/v1/tenant-branches/branch-1',
    );
  });

  test(
    'throws StateError when no tenant branch id is stored (non-tenant '
    'session)',
    () async {
      final storage = FakeLocalStorage();
      final container = ProviderContainer(
        overrides: [localStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(currentTenantBranchProvider.future),
        throwsA(isA<StateError>()),
      );
    },
  );
}

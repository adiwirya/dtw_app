import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_branch_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/canned_dio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('fetchBranch', () {
    test('parses the live response shape', () async {
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
      final repository = TenantBranchRepository(dio: dio);

      final branch = await repository.fetchBranch(branchId: 'branch-1');

      expect(branch.id, 'branch-1');
      expect(branch.brandId, 'brand-1');
      expect(branch.branchName, 'Janji Jiwa Summarecon');
      expect(
        (dio.httpClientAdapter as CannedAdapter).lastRequest!.path,
        '/v1/tenant-branches/branch-1',
      );
    });

    test('throws a mapped ApiException on failure', () async {
      final dio = cannedDio(500, {
        'meta': {
          'success': false,
          'message': 'Error',
          'code': 500,
          'trace_id': 'abc',
        },
      });
      final repository = TenantBranchRepository(dio: dio);

      await expectLater(
        repository.fetchBranch(branchId: 'branch-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('fetchBrandLogoUrl', () {
    test('returns the logo_url from the brand payload', () async {
      final dio = cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Success',
          'code': 200,
          'trace_id': 'abc',
        },
        'data': {'id': 'brand-1', 'logo_url': 'https://cdn/logo.png'},
      });
      final repository = TenantBranchRepository(dio: dio);

      final logoUrl = await repository.fetchBrandLogoUrl(brandId: 'brand-1');

      expect(logoUrl, 'https://cdn/logo.png');
      expect(
        (dio.httpClientAdapter as CannedAdapter).lastRequest!.path,
        '/v1/brands/brand-1',
      );
    });

    test('returns null when the brand has no logo', () async {
      final dio = cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Success',
          'code': 200,
          'trace_id': 'abc',
        },
        'data': {'id': 'brand-1', 'logo_url': null},
      });
      final repository = TenantBranchRepository(dio: dio);

      final logoUrl = await repository.fetchBrandLogoUrl(brandId: 'brand-1');

      expect(logoUrl, isNull);
    });

    test('throws a mapped ApiException on failure', () async {
      final dio = cannedDio(404, {
        'meta': {
          'success': false,
          'message': 'Not found',
          'code': 404,
          'trace_id': 'abc',
        },
      });
      final repository = TenantBranchRepository(dio: dio);

      await expectLater(
        repository.fetchBrandLogoUrl(brandId: 'brand-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

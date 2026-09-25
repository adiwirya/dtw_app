import 'package:dtw_app/features/tenant/data/models/tenant_branch.dart';
import 'package:flutter_test/flutter_test.dart';

TenantBranch _branch({DateTime? createdAt}) => TenantBranch(
      id: 'branch-1',
      brandId: 'brand-1',
      brandName: 'Janji Jiwa',
      branchName: 'Janji Jiwa Summarecon',
      areaName: 'Downtown',
      locationCode: 'SMB',
      isActive: true,
      createdAt: createdAt ?? DateTime(2026, 8, 7),
    );

void main() {
  group('TenantBranch.fromJson', () {
    test('parses the live GET /v1/tenant-branches/{id} response shape', () {
      final branch = TenantBranch.fromJson(const {
        'id': 'branch-1',
        'brand_id': 'brand-1',
        'brand_name': 'Janji Jiwa',
        'branch_name': 'Janji Jiwa Summarecon',
        'area_name': 'Downtown',
        'kd_lokasi': 'SMB',
        'is_active': true,
        'created_at': '2026-08-07 09:16:59',
      });

      expect(branch.id, 'branch-1');
      expect(branch.brandId, 'brand-1');
      expect(branch.brandName, 'Janji Jiwa');
      expect(branch.branchName, 'Janji Jiwa Summarecon');
      expect(branch.areaName, 'Downtown');
      expect(branch.locationCode, 'SMB');
      expect(branch.isActive, isTrue);
      expect(branch.createdAt, DateTime(2026, 8, 7, 9, 16, 59));
    });

    test('parses a space-separated created_at into a DateTime', () {
      final branch = TenantBranch.fromJson(const {
        'id': 'branch-1',
        'brand_id': 'brand-1',
        'brand_name': 'Janji Jiwa',
        'branch_name': 'Janji Jiwa Summarecon',
        'area_name': 'Downtown',
        'kd_lokasi': 'SMB',
        'is_active': false,
        'created_at': '2026-01-05 00:00:00',
      });

      expect(branch.isActive, isFalse);
      expect(branch.createdAt, DateTime(2026, 1, 5));
    });
  });

  group('toTenantAdminInfo', () {
    test('formats the joined date as "<day> <Indonesian month> <year>"', () {
      final info = _branch(createdAt: DateTime(2026, 8, 7)).toTenantAdminInfo();

      expect(info.name, 'Janji Jiwa Summarecon');
      expect(info.joinedLabel, '7 Agustus 2026');
    });

    test('resolves every month name correctly (boundary: Jan + Dec)', () {
      expect(
        _branch(createdAt: DateTime(2026)).toTenantAdminInfo().joinedLabel,
        '1 Januari 2026',
      );
      expect(
        _branch(createdAt: DateTime(2026, 12, 31))
            .toTenantAdminInfo()
            .joinedLabel,
        '31 Desember 2026',
      );
    });

    test('passes brandLogoUrl through when given', () {
      final info = _branch().toTenantAdminInfo(brandLogoUrl: 'https://cdn/logo.png');

      expect(info.logoUrl, 'https://cdn/logo.png');
    });

    test('leaves logoUrl null when omitted', () {
      final info = _branch().toTenantAdminInfo();

      expect(info.logoUrl, isNull);
    });
  });
}

import 'package:dtw_app/features/tenant/data/models/tenant_admin_info.dart';
import 'package:flutter/foundation.dart';

/// A tenant branch's identity, as returned by `GET /v1/tenant-branches/{id}`
/// (confirmed live, and cross-checked against the full OpenAPI spec at
/// `/docs/api/` — see `docs/api-reference.md`).
///
/// **Known gap:** the endpoint has no booth/location, rating, contact or
/// operating-hours fields — [toTenantAdminInfo] leaves those slots null so
/// the Admin screen can hide them rather than show fabricated values. The
/// endpoint's own `banner_url` is a wide promotional banner (spec requires
/// min. 1280x720px), not the round brand logo the Admin hero shows — that
/// comes from the separate `GET /v1/brands/{brandId}` `logo_url` instead
/// (see [brandId] and `AdminStatusProvider`).
@immutable
class TenantBranch {
  const TenantBranch({
    required this.id,
    required this.brandId,
    required this.brandName,
    required this.branchName,
    required this.areaName,
    required this.isActive,
    required this.createdAt,
  });

  factory TenantBranch.fromJson(Map<String, dynamic> json) {
    return TenantBranch(
      id: json['id'] as String,
      brandId: json['brand_id'] as String,
      brandName: json['brand_name'] as String,
      branchName: json['branch_name'] as String,
      areaName: json['area_name'] as String,
      isActive: json['is_active'] as bool,
      createdAt:
          DateTime.parse((json['created_at'] as String).replaceFirst(' ', 'T')),
    );
  }

  final String id;
  final String brandId;
  final String brandName;
  final String branchName;
  final String areaName;
  final bool isActive;
  final DateTime createdAt;

  static const _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// [brandLogoUrl] is a separate fetch (`GET /v1/brands/{brandId}`,
  /// `logo_url`) — the caller passes through whatever it resolved to
  /// (including null on a best-effort fetch failure).
  TenantAdminInfo toTenantAdminInfo({String? brandLogoUrl}) {
    final month = _months[createdAt.month - 1];
    return TenantAdminInfo(
      name: branchName,
      joinedLabel: '${createdAt.day} $month ${createdAt.year}',
      logoUrl: brandLogoUrl,
    );
  }
}

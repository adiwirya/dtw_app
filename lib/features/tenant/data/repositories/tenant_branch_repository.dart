import 'package:dio/dio.dart';
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/network/dio_provider.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_branch.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tenant_branch_repository.g.dart';

class TenantBranchRepository {
  const TenantBranchRepository({required this._dio});

  final Dio _dio;

  Future<TenantBranch> fetchBranch({required String branchId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/tenant-branches/$branchId',
      );
      return TenantBranch.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// The brand's round logo (`GET /v1/brands/{brandId}`, `logo_url`) — a
  /// display nicety, not core profile data, so a failure here must never
  /// fail the whole tenant-admin-info fetch. Callers treat a thrown error the
  /// same as a null logo (see `tenantAdminInfo`).
  Future<String?> fetchBrandLogoUrl({required String brandId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/brands/$brandId',
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return data['logo_url'] as String?;
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}

@riverpod
TenantBranchRepository tenantBranchRepository(Ref ref) =>
    TenantBranchRepository(dio: ref.watch(dioProvider));

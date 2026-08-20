import 'package:dio/dio.dart';
import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/network/dio_provider.dart';
import 'package:dtw_app/features/tenant/data/models/modifier_group.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'modifier_group_repository.g.dart';

class ModifierGroupRepository {
  const ModifierGroupRepository({required this._dio});

  final Dio _dio;

  Future<List<ModifierGroup>> fetchModifierGroups({
    required String brandId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/modifier-groups',
        queryParameters: {'brand_id': brandId},
      );
      final data = response.data!['data'] as List;
      return data
          .map((json) => ModifierGroup.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// Creates a modifier group ("Simpan Varian"). The response is the same
  /// shape as [fetchModifierGroups]'s items (confirmed live), just with an
  /// empty `options: []` — options are added one at a time afterwards via
  /// [addOption], since they can only be attached to a group that exists.
  Future<ModifierGroup> createModifierGroup({
    required String brandId,
    required String name,
    required int minSelections,
    required int maxSelections,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/modifier-groups',
        data: {
          'brand_id': brandId,
          'name': name,
          'min_selections': minSelections,
          'max_selections': maxSelections,
        },
      );
      return ModifierGroup.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// Adds one option to an existing modifier group.
  Future<void> addOption(
    String groupId, {
    required String name,
    required int price,
  }) async {
    try {
      await _dio.post<void>(
        '/v1/modifier-groups/$groupId/options',
        data: {'name': name, 'price': price},
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// Gets one modifier group with its options — used to load `varian-diisi`
  /// (edit an existing variant) with real data instead of the old hardcoded
  /// "Ukuran Minuman" seed.
  Future<ModifierGroup> fetchModifierGroup(String groupId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/modifier-groups/$groupId',
      );
      return ModifierGroup.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// Updates a modifier group's name/rules. `is_active` is required by the
  /// endpoint (confirmed live — a 422 without it) even though this app has
  /// no UI to deactivate a variant yet, so callers always pass `true`.
  Future<ModifierGroup> updateModifierGroup(
    String groupId, {
    required String name,
    required int minSelections,
    required int maxSelections,
    required bool isActive,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/v1/modifier-groups/$groupId',
        data: {
          'name': name,
          'min_selections': minSelections,
          'max_selections': maxSelections,
          'is_active': isActive,
        },
      );
      return ModifierGroup.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// Updates one existing option's name/price. There is no delete endpoint
  /// for an option (confirmed live: `DELETE` returns 405) — an option can
  /// only ever be renamed/repriced, never removed, once saved.
  Future<void> updateOption(
    String groupId,
    String optionId, {
    required String name,
    required int price,
  }) async {
    try {
      await _dio.put<void>(
        '/v1/modifier-groups/$groupId/options/$optionId',
        data: {'name': name, 'price': price},
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}

@riverpod
ModifierGroupRepository modifierGroupRepository(Ref ref) =>
    ModifierGroupRepository(dio: ref.watch(dioProvider));

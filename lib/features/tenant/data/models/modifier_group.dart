import 'package:dtw_app/core/utils/currency.dart';
import 'package:dtw_app/features/tenant/presentation/providers/variant_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/variant_rows.dart';
import 'package:flutter/foundation.dart';

/// A brand's modifier group ("Varian" in the tenant UI), as returned by
/// `GET /v1/modifier-groups` (confirmed live — see `docs/api-reference.md`).
///
/// **Known gaps:**
/// - The list endpoint returns [optionCount] but not [options] themselves —
///   only `GET/POST/PUT /v1/modifier-groups/{id}` do (this is why [options]
///   is nullable: null means "count known, names not fetched").
/// - There is no "used in N menu products" field anywhere in the API —
///   [VariantData.usedInMenuCount] stays null.
/// - There is no delete endpoint for a group or an option (confirmed live:
///   `DELETE` on either route returns 405) — see `VariantList.updateVariant`.
@immutable
class ModifierGroup {
  const ModifierGroup({
    required this.id,
    required this.name,
    required this.isRequired,
    required this.maxSelections,
    required this.optionCount,
    this.options,
  });

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List?;
    return ModifierGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      isRequired: json['is_required'] as bool,
      maxSelections: (json['max_selections'] as num).toInt(),
      optionCount: (json['option_count'] as num).toInt(),
      options: rawOptions == null
          ? null
          : [
              for (final o in rawOptions.cast<Map<String, dynamic>>())
                VariantOptionData(
                  id: o['id'] as String,
                  name: o['name'] as String,
                  addonPrice: (o['total_price'] as num).toInt() == 0
                      ? null
                      : formatRupiah((o['total_price'] as num).toInt()),
                ),
            ],
    );
  }

  final String id;
  final String name;
  final bool isRequired;

  /// The API has no explicit single/multi enum — [VariantType.ganda] is
  /// derived from allowing more than one selection.
  final int maxSelections;
  final int optionCount;

  /// Only present on the detail/create/update responses (`GET`, `POST`, and
  /// `PUT /v1/modifier-groups/{id}`) — null from the list endpoint.
  final List<VariantOptionData>? options;

  VariantType get type =>
      maxSelections > 1 ? VariantType.ganda : VariantType.tunggal;

  /// [overrideOptions] lets a caller that already knows the option names
  /// from elsewhere (e.g. just after creating this group — see
  /// `VariantList.create`) attach them directly, taking priority over
  /// [options] parsed off this response.
  VariantData toVariantData({List<VariantOptionData>? overrideOptions}) {
    final resolvedOptions = overrideOptions ?? options;
    return VariantData(
      id: id,
      name: name,
      type: type,
      isRequired: isRequired,
      multiSelect: type == VariantType.ganda,
      optionCount: resolvedOptions?.length ?? optionCount,
      options: resolvedOptions,
    );
  }
}

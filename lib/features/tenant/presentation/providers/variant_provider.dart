import 'package:dtw_app/core/utils/currency.dart';
import 'package:dtw_app/features/tenant/data/repositories/modifier_group_repository.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/variant_rows.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'variant_provider.g.dart';

/// A tenant menu variant (e.g. `Tingkat Pedas`) with its options and the two
/// L6 selection rules.
@immutable
class VariantData {
  const VariantData({
    required this.id,
    required this.name,
    required this.type,
    required this.optionCount,
    this.options,
    this.isRequired = false,
    this.multiSelect = false,
    this.usedInMenuCount,
  });

  /// The backing modifier group id (`ModifierGroup.id`).
  final String id;

  /// Variant name, e.g. `Tingkat Pedas`.
  final String name;

  /// Single-choice (`Tunggal`) vs. multi-choice (`Ganda`) — the type chip.
  final VariantType type;

  /// How many options this variant has. Always known (even when [options]
  /// itself isn't — see below), since `GET /v1/modifier-groups` returns an
  /// `option_count` without the options themselves.
  final int optionCount;

  /// The selectable options with names/add-on prices — only known once
  /// fetched in detail (`GET /v1/modifier-groups/{id}`, or from the
  /// in-progress `tambah-varian` form). Null means "count known, names
  /// not fetched"; renderers show [optionCount] regardless and skip the
  /// name preview when this is null.
  final List<VariantOptionData>? options;

  /// L6 rule "Wajib Dipilih" — the customer must pick an option.
  final bool isRequired;

  /// L6 rule "Pilih Lebih dari Satu" — the customer may pick several options.
  final bool multiSelect;

  /// How many menus reference this variant ("Digunakan di N menu"). No API
  /// source exists for this yet — null hides the footer that shows it.
  final int? usedInMenuCount;

  /// Option labels for the comma-joined preview. Empty when [options] is
  /// unknown (see above) — callers gate the preview line on `options != null`
  /// rather than on this being non-empty.
  List<String> get optionNames => [
        for (final o in options ?? const <VariantOptionData>[]) o.name,
      ];

  /// Projection onto the reused [VariantSelectRow] value object.
  ///
  /// [optionCount] is passed through explicitly — it is known even when
  /// [options] (and therefore [optionNames]) is not.
  VariantSelectData get asSelectData => VariantSelectData(
        name: name,
        type: type,
        optionNames: optionNames,
        optionCount: optionCount,
      );
}

/// The tenant's variant list (`kelola-varian` / `varian-disimpan`), fetched
/// from `GET /v1/modifier-groups`.
@riverpod
class VariantList extends _$VariantList {
  @override
  Future<List<VariantData>> build() async {
    final branch = await ref.watch(currentTenantBranchProvider.future);
    final groups = await ref
        .watch(modifierGroupRepositoryProvider)
        .fetchModifierGroups(brandId: branch.brandId);
    return [for (final group in groups) group.toVariantData()];
  }

  /// Creates a new variant ("Simpan Varian" on `tambah-varian-2`): creates
  /// the modifier group, then adds each of [options] to it in sequence —
  /// only possible once the group exists, so there is no batch-create
  /// endpoint to use instead. [isRequired] maps to `min_selections` (1 or 0)
  /// and [multiSelect] to `max_selections` (the option count, so the
  /// customer may pick up to all of them — the API has no explicit cap
  /// field for this). Appends the new variant to the list on success rather
  /// than refetching, since every field is already known from the responses.
  Future<void> create({
    required String name,
    required bool isRequired,
    required bool multiSelect,
    required List<VariantOptionData> options,
  }) async {
    final branch = await ref.read(currentTenantBranchProvider.future);
    final repository = ref.read(modifierGroupRepositoryProvider);
    final group = await repository.createModifierGroup(
      brandId: branch.brandId,
      name: name,
      minSelections: isRequired ? 1 : 0,
      maxSelections: multiSelect ? options.length : 1,
    );
    for (final option in options) {
      await repository.addOption(
        group.id,
        name: option.name,
        price: parseRupiah(option.addonPrice),
      );
    }
    final current = state.value ?? const [];
    state = AsyncData([
      ...current,
      group.toVariantData(overrideOptions: options),
    ]);
  }

  /// Updates an existing variant ("Simpan Varian" on `varian-diisi`).
  ///
  /// Named `updateVariant`, not `update`, to avoid colliding with
  /// [AsyncNotifier]'s own inherited `update(fn)` method (a different
  /// operation: it re-derives state from the current value).
  ///
  /// Each option in [options] is either updated in place (`PUT`, when it has
  /// an [VariantOptionData.id] — it was already saved) or created (`POST`,
  /// when it doesn't — the user added it in this editing session). There is
  /// no delete endpoint, so an option removed from [options] that was
  /// already saved is NOT reflected on the server — `TambahVarianScreen`
  /// only offers removal for not-yet-saved options for exactly this reason.
  /// Refetches the group afterwards (rather than assembling the result
  /// locally like [create] does) so newly-added options end up with their
  /// real ids.
  Future<void> updateVariant({
    required String groupId,
    required String name,
    required bool isRequired,
    required bool multiSelect,
    required List<VariantOptionData> options,
  }) async {
    final repository = ref.read(modifierGroupRepositoryProvider);
    await repository.updateModifierGroup(
      groupId,
      name: name,
      minSelections: isRequired ? 1 : 0,
      maxSelections: multiSelect ? options.length : 1,
      isActive: true,
    );
    for (final option in options) {
      final price = parseRupiah(option.addonPrice);
      if (option.id case final optionId?) {
        await repository.updateOption(
          groupId,
          optionId,
          name: option.name,
          price: price,
        );
      } else {
        await repository.addOption(groupId, name: option.name, price: price);
      }
    }
    final refreshed = await repository.fetchModifierGroup(groupId);
    final current = state.value ?? const [];
    state = AsyncData([
      for (final variant in current)
        if (variant.id == groupId) refreshed.toVariantData() else variant,
    ]);
  }
}

/// A variant attached to a menu, previewed in the menu form's "Varian Menu"
/// card on the `varian-ditambahkan` frame.
@immutable
class MenuVariantEntry {
  const MenuVariantEntry({required this.name, required this.optionsPreview});

  /// Variant name, e.g. `Level Kepedasan`.
  final String name;

  /// Comma-joined option preview shown under the name, e.g. `Original, Spicy`.
  final String optionsPreview;
}

/// The two variants shown attached to the menu on `varian-ditambahkan`. Mock.
const List<MenuVariantEntry> attachedMenuVariants = [
  MenuVariantEntry(name: 'Level Kepedasan', optionsPreview: 'Original, Spicy'),
  MenuVariantEntry(name: 'Ukuran Size', optionsPreview: 'Regular, Large'),
];

import 'package:dtw_app/features/tenant/presentation/widgets/variant_rows.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'variant_provider.g.dart';

// TODO(open-question): the Variant data source and the variant-form validation
// rules (required / multi-select semantics, option add-on pricing) are
// unresolved Open Questions on this work item. Everything below is hard-coded,
// in-memory mock data harvested from the tenant `kelola-varian` /
// `tambah-varian` / `varian-disimpan` Figma references, and every [VariantList]
// mutation is a UI-only mock (no persistence). When the real source lands,
// replace this synchronous class-notifier with an async repository fetch
// (`Future<List<VariantData>>` backed by dio, per
// knowledge/riverpod-patterns.md) and have the screens consume the AsyncValue.

/// A tenant menu variant (e.g. `Tingkat Pedas`) with its options and the two
/// L6 selection rules.
@immutable
class VariantData {
  const VariantData({
    required this.name,
    required this.type,
    required this.options,
    this.isRequired = false,
    this.multiSelect = false,
    this.usedInMenuCount = 0,
  });

  /// Variant name, e.g. `Tingkat Pedas`.
  final String name;

  /// Single-choice (`Tunggal`) vs. multi-choice (`Ganda`) — the type chip.
  final VariantType type;

  /// The selectable options. L6: each [VariantOptionData] carries a "+price"
  /// add-on (`addonPrice`, null => Gratis).
  final List<VariantOptionData> options;

  /// L6 rule "Wajib Dipilih" — the customer must pick an option.
  final bool isRequired;

  /// L6 rule "Pilih Lebih dari Satu" — the customer may pick several options.
  final bool multiSelect;

  /// How many menus reference this variant ("Digunakan di N menu"). Mock count.
  final int usedInMenuCount;

  /// Option labels for the comma-joined preview / `N Opsi` count.
  List<String> get optionNames => [for (final o in options) o.name];

  /// Projection onto the reused [VariantSelectRow] value object.
  VariantSelectData get asSelectData => VariantSelectData(
        name: name,
        type: type,
        optionNames: optionNames,
      );

  /// Returns a copy with [options] replaced (used by the mock `addOption`).
  VariantData copyWith({List<VariantOptionData>? options}) => VariantData(
        name: name,
        type: type,
        options: options ?? this.options,
        isRequired: isRequired,
        multiSelect: multiSelect,
        usedInMenuCount: usedInMenuCount,
      );
}

/// Seed variants shown on `varian-disimpan` (the saved list) and offered on the
/// `tambah-varian` ("Pilih Varian") picker. Mock data mirroring the references.
const List<VariantData> savedVariants = [
  VariantData(
    name: 'Tingkat Pedas',
    type: VariantType.tunggal,
    isRequired: true,
    options: [
      VariantOptionData(name: 'Original'),
      VariantOptionData(name: 'Spicy'),
    ],
    usedInMenuCount: 12,
  ),
  VariantData(
    name: 'Ukuran Minuman',
    type: VariantType.tunggal,
    isRequired: true,
    options: [
      VariantOptionData(name: 'Small'),
      VariantOptionData(name: 'Medium', addonPrice: 'Rp3.000'),
      VariantOptionData(name: 'Large', addonPrice: 'Rp5.000'),
    ],
    usedInMenuCount: 8,
  ),
  VariantData(
    name: 'Extra Topping',
    type: VariantType.ganda,
    multiSelect: true,
    options: [
      VariantOptionData(name: 'Keju', addonPrice: 'Rp3.000'),
      VariantOptionData(name: 'Telur', addonPrice: 'Rp3.000'),
      VariantOptionData(name: 'Sosis', addonPrice: 'Rp5.000'),
      VariantOptionData(name: 'Jamur', addonPrice: 'Rp4.000'),
      VariantOptionData(name: 'Bacon', addonPrice: 'Rp7.000'),
    ],
    usedInMenuCount: 4,
  ),
];

/// Mutable in-memory variant list backing `kelola-varian` (the manage screen).
///
/// Starts EMPTY to match the empty `kelola-varian` frame. UI-only: [add]
/// appends a newly-created variant (the Tambah Varian flow) and [loadSaved]
/// seeds the `savedVariants` mock. No persistence.
@riverpod
class VariantList extends _$VariantList {
  @override
  List<VariantData> build() => const [];

  /// Appends [variant] to the list (mock save from the variant form).
  void add(VariantData variant) => state = [...state, variant];

  /// Loads the seeded [savedVariants] (mock "already saved" state).
  void loadSaved() => state = savedVariants;

  /// Attaches [option] to the variant at [index] (UI-only mock of the
  /// "+ Tambah Opsi" → option modal (`opsi-varian-1`) → variant flow).
  ///
  // TODO(open-question): with no persisted draft-variant model yet, this
  // appends to an already-added [VariantData]; the real flow will attach the
  // option to the in-progress variant before it is saved.
  void addOption(int index, VariantOptionData option) {
    if (index < 0 || index >= state.length) return;
    final updated = [...state];
    final target = updated[index];
    updated[index] = target.copyWith(options: [...target.options, option]);
    state = updated;
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

import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_toggle.dart';
import 'package:flutter/material.dart';

/// Whether a variant lets the customer pick one option ([tunggal] / single) or
/// several ([ganda] / multi). Shown as the "Tunggal" / "Ganda" chip on the
/// `tambah-varian` ("Pilih Varian") picker rows.
enum VariantType { tunggal, ganda }

/// Value object backing a [VariantSelectRow] (`tambah-varian` picker list).
@immutable
class VariantSelectData {
  const VariantSelectData({
    required this.name,
    required this.type,
    required this.optionCount,
    this.optionNames = const [],
  });

  /// Variant name, e.g. `Tingkat Pedas`.
  final String name;

  /// Single vs. multi choice — renders the type chip.
  final VariantType type;

  /// How many options the variant has, for the `N Opsi` line.
  ///
  /// Deliberately independent of [optionNames]: a variant fetched from
  /// `GET /v1/modifier-groups` knows its `option_count` but not its option
  /// names. Deriving this from the names instead rendered every such row as
  /// `0 Opsi`, which is why it is now passed explicitly.
  final int optionCount;

  /// Option labels, e.g. `['Original', 'Spicy']`. Empty when the names aren't
  /// known (the list endpoint doesn't return them) — the row previews these
  /// only when non-empty.
  final List<String> optionNames;
}

/// Multi-select picker row for attaching existing variants to a menu
/// (`tambah-varian` / "Pilih Varian"). A leading checkbox drives the
/// multi-selection; the row shows the variant name, a Tunggal/Ganda chip, the
/// option count and a comma-joined option preview.
class VariantSelectRow extends StatelessWidget {
  const VariantSelectRow({
    required this.data,
    required this.selected,
    required this.onSelectedChanged,
    super.key,
  });

  /// The variant to render.
  final VariantSelectData data;

  /// Whether this variant is currently ticked.
  final bool selected;

  /// Called with the new selection when the checkbox (or row) is tapped.
  final ValueChanged<bool> onSelectedChanged;

  static const double _radius = 12;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            offset: Offset(0, 2),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onSelectedChanged(!selected),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _checkbox(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              data.name,
                              style: const TextStyle(
                                color: AppColors.neutral900,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _typeChip(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${data.optionCount} Opsi',
                        style: const TextStyle(
                          color: AppColors.neutral500,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      // `GET /v1/modifier-groups` returns `option_count`
                      // without the options themselves, so a variant from the
                      // list endpoint has no names to preview. Rendering the
                      // join unconditionally left a blank line under the
                      // count — mirrors the same guard in
                      // `KelolaVarianScreen`'s card.
                      if (data.optionNames.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          data.optionNames.join(', '),
                          style: const TextStyle(
                            color: AppColors.neutral500,
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _checkbox() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: selected ? AppColors.successGreen : AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: selected ? AppColors.successGreen : AppColors.neutral100,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: AppColors.white)
          : null,
    );
  }

  Widget _typeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successTint,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        data.type == VariantType.tunggal ? 'Tunggal' : 'Ganda',
        style: const TextStyle(
          color: AppColors.success700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}

/// A title + description + [AppToggle] row used for the variant "Aturan
/// Pilihan" (`tambah-varian`): "Wajib Dipilih" (required) and "Pilih Lebih dari
/// Satu" (multi-select). This is the multi-select/required control (L6); two
/// instances model a variant's rules.
class VariantRuleToggleRow extends StatelessWidget {
  const VariantRuleToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Rule name, e.g. `Wajib Dipilih` / `Pilih Lebih dari Satu`.
  final String title;

  /// Explanatory caption under the title.
  final String subtitle;

  /// Current rule state.
  final bool value;

  /// Called with the new value when the toggle flips.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.neutral500,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AppToggle(
          value: value,
          semanticLabel: title,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Value object backing a [VariantOptionRow] (`opsi-2-ditambahkan`).
@immutable
class VariantOptionData {
  const VariantOptionData({
    required this.name,
    this.addonPrice,
    this.id,
  });

  /// The backing modifier-option id (`GET/PUT /v1/modifier-groups/{id}` —
  /// only known for options already saved to the API). Null for an option
  /// the user just added in the current editing session and hasn't saved
  /// yet — that distinction is what tells `VariantList.updateVariant`
  /// whether to `POST` (create) or `PUT` (update) each option, and what lets
  /// the "Tambah Varian" form only offer to remove not-yet-saved options
  /// (there is no delete endpoint for an already-saved one).
  final String? id;

  /// Option name, e.g. `Small` / `Medium`.
  final String name;

  /// Pre-formatted add-on price, e.g. `Rp3.000`. Null / empty => free
  /// (rendered as `Gratis`); otherwise rendered as `+<addonPrice>` (L6, the
  /// "+price" add-on). No currency math here.
  final String? addonPrice;

  bool get isFree => addonPrice == null || addonPrice!.isEmpty;
}

/// An added variant option row (`opsi-2-ditambahkan`): a reorder handle, the
/// option name, the add-on price (`Gratis` or `+Rp3.000`) and a remove button.
class VariantOptionRow extends StatelessWidget {
  const VariantOptionRow({
    required this.data,
    this.onRemove,
    this.showReorderHandle = true,
    super.key,
  });

  /// The option to render.
  final VariantOptionData data;

  /// Called when the remove (minus) button is tapped. Null hides the button.
  final VoidCallback? onRemove;

  /// Whether to show the leading drag handle (reorderable list affordance).
  final bool showReorderHandle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          if (showReorderHandle) ...[
            const Icon(
              Icons.drag_indicator,
              size: 20,
              color: AppColors.neutral300,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              data.name,
              style: const TextStyle(
                color: AppColors.neutral900,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            data.isFree ? 'Gratis' : '+${data.addonPrice}',
            style: const TextStyle(
              color: AppColors.neutral500,
              fontSize: 14,
              height: 1.2,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              child: const Icon(
                Icons.remove_circle_outline,
                size: 22,
                color: AppColors.dangerRed,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

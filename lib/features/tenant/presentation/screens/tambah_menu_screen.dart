import 'dart:async';

import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/app_toggle.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/tenant/presentation/providers/menu_provider.dart';
import 'package:dtw_app/features/tenant/presentation/providers/variant_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_item_card.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/menu_success_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:obra_icons/obra_icons.dart';

/// The add-menu / fill-menu form (`tambah-menu` empty, `menu-diisi` filled).
///
/// Reflects the L6 design decisions layered over the cached references:
///   * the "best seller" flag becomes a single **Populer** (PIN) toggle,
///   * the **Promo** toggle and the **Status Menu** (stock availability) toggle
///     are removed,
///   * a **Diskon** card adds the two discount inputs (percentage + price) plus
///     a "Berlaku Sampai" valid-date field.
///
/// `Tambah Varian` and the `Kelola Varian` entry both route to
/// [TenantRoutes.kelolaVarian] (item 07's sub-flow). `Simpan Menu` performs a
/// mock save (appends to [MenuList]) then raises the `berhasil-ditambahkan`
/// success modal before advancing to `menu-berhasil-ditambahkan`.
///
// TODO(open-question): the menu data source and per-field validation rules are
// unresolved (Open Questions 3/5/6). Dropdown/price/date fields are display-only
// mocks and no validation runs — wire real editing + validation once the source
// and rules land.
class TambahMenuScreen extends ConsumerStatefulWidget {
  const TambahMenuScreen({
    this.prefilled = false,
    this.variants = const [],
    this.onBack,
    super.key,
  });

  /// Seeds the `menu-diisi` filled state (name/category/price/tags populated).
  final bool prefilled;

  /// Variants attached to the menu, shown in the "Varian Menu" card on the
  /// `varian-ditambahkan` frame. Empty on the plain `tambah-menu` / `menu-diisi`
  /// frames.
  final List<MenuVariantEntry> variants;

  /// Overrides the top-bar back action (used by the `varian-ditambahkan` route
  /// to return to `menu-berhasil-ditambahkan`). Falls back to `context.pop()`.
  final VoidCallback? onBack;

  @override
  ConsumerState<TambahMenuScreen> createState() => _TambahMenuScreenState();
}

class _TambahMenuScreenState extends ConsumerState<TambahMenuScreen> {
  late final TextEditingController _name;
  late final TextEditingController _note;
  late bool _populer;

  // Display-only mock selections (dropdowns/price/date are not yet editable).
  late final String? _category;
  late final String _price;
  late final List<String> _tags;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: widget.prefilled ? 'Paket Komplit' : '',
    );
    _note = TextEditingController();
    _populer = false;
    _category = widget.prefilled ? 'Nasi' : null;
    _price = widget.prefilled ? '32.000' : '';
    _tags = widget.prefilled ? const ['Chicken', 'Combo Meal'] : const [];
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(menuListProvider.notifier).add(
          MenuItemData(
            // Mock save only (see the TODO in menu_provider.dart) — this id
            // never reaches the API, just needs to be unique in the local list.
            id: 'mock-${DateTime.now().microsecondsSinceEpoch}',
            name: _name.text.isEmpty ? 'Menu Baru' : _name.text,
            price: _price.isEmpty ? 'Rp0' : 'Rp$_price',
            popular: _populer,
          ),
        );
    unawaited(
      showMenuSuccessModal(
        context,
        onConfirm: () => context.goNamed(TenantRoutes.menuBerhasil),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onBack: widget.onBack ??
                  () => context.canPop() ? context.pop() : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _PhotoCard(),
                    const SizedBox(height: 16),
                    _fieldsCard(),
                    const SizedBox(height: 16),
                    _diskonCard(),
                    const SizedBox(height: 16),
                    _populerCard(),
                    const SizedBox(height: 16),
                    _varianCard(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: PrimaryButton(label: 'Simpan Menu', onPressed: _save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldsCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LabeledField(
            label: 'Nama Menu',
            required: true,
            child: AppInput(
              controller: _name,
              hintText: 'Contoh : Ayam Geprek',
              trailing: _Counter(controller: _name, max: 50),
            ),
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'Kategori',
            required: true,
            child: _DropdownBox(value: _category, hint: 'Pilih Kategori'),
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'Harga',
            required: true,
            child: _PriceBox(value: _price, hint: 'Contoh : 25.000'),
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'Tag',
            optional: true,
            child: _tags.isEmpty
                ? const _DropdownBox(value: null, hint: 'Pilih Tag')
                : _TagBox(tags: _tags),
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'Catatan',
            child: _TextBox(
              controller: _note,
              hint: 'Masukkan catatan menu',
              minLines: 3,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  // L6: dedicated discount card (percentage + price + valid date).
  Widget _diskonCard() {
    return const _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Diskon',
            style: TextStyle(
              color: AppColors.neutral900,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Atur potongan harga dan masa berlakunya jika ada',
            style: TextStyle(
              color: AppColors.neutral500,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Diskon (%)',
                  child: _PercentBox(hint: 'Contoh : 10'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _LabeledField(
                  label: 'Harga Diskon',
                  child: _PriceBox(value: '', hint: 'Otomatis'),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _LabeledField(
            label: 'Berlaku Sampai',
            child: _DateBox(hint: 'Pilih tanggal'),
          ),
        ],
      ),
    );
  }

  // L6: single Populer (PIN) toggle — Promo and Status Menu removed.
  Widget _populerCard() {
    return _Card(
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Populer',
                  style: TextStyle(
                    color: AppColors.neutral900,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Sematkan (PIN) sebagai menu populer di aplikasi customer',
                  style: TextStyle(
                    color: AppColors.neutral500,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppToggle(
            value: _populer,
            semanticLabel: 'Populer',
            onChanged: (v) => setState(() => _populer = v),
          ),
        ],
      ),
    );
  }

  Widget _varianCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Varian Menu',
                style: TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${widget.variants.length})',
                style: const TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Tambahkan varian (size, level pedas, dll) dengan tambahan harga '
            'jika ada',
            style: TextStyle(
              color: AppColors.neutral500,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          for (final v in widget.variants) ...[
            _AttachedVariantRow(entry: v),
            const SizedBox(height: 12),
          ],
          _OutlinedGreenButton(
            label: 'Tambah Varian',
            onTap: () => context.goNamed(TenantRoutes.kelolaVarian),
          ),
        ],
      ),
    );
  }
}

// --- Top bar ---------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _IconButton(icon: ObraIcons.arrow_left, onTap: onBack),
            const Expanded(
              child: Center(
                child: Text(
                  'Tambah Menu',
                  style: TextStyle(
                    color: AppColors.neutral900,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            const _IconButton(icon: ObraIcons.sliders),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 20,
      child: Icon(icon, size: 24, color: AppColors.neutral900),
    );
  }
}

// --- Photo card ------------------------------------------------------------

class _PhotoCard extends StatelessWidget {
  const _PhotoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 183,
      decoration: BoxDecoration(
        color: AppColors.neutralTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // TODO(open-question): menu photo raster isn't in the asset cache;
          // a placeholder tile stands in for both the empty and filled frames
          // (mirrors MenuItemCard's thumbnail).
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.image_outlined,
              size: 40,
              color: AppColors.neutral300,
            ),
          ),
          const SizedBox(height: 16),
          _UbahFotoButton(),
        ],
      ),
    );
  }
}

class _UbahFotoButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(100),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            offset: Offset(0, 2),
            blurRadius: 16,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ObraIcons.image, size: 16, color: AppColors.neutral900),
          SizedBox(width: 8),
          Text(
            'Ubah Foto',
            style: TextStyle(
              color: AppColors.neutral900,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Field primitives ------------------------------------------------------

/// White rounded section card matching the tenant `_SectionCard` style.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            offset: Offset(0, 2),
            blurRadius: 16,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

/// A label row (with optional required asterisk / `(Optional)` hint) above a
/// field box.
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.required = false,
    this.optional = false,
  });

  final String label;
  final Widget child;
  final bool required;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.dangerRed,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            if (optional)
              const Text(
                ' (Optional)',
                style: TextStyle(
                  color: AppColors.neutral300,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// The shared 12-radius, neutral-bordered field box.
class _Box extends StatelessWidget {
  const _Box({required this.child, this.height = 40, this.padded = true});

  final Widget child;
  final double height;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: height),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral100),
      ),
      padding: padded
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
          : EdgeInsets.zero,
      child: child,
    );
  }
}

const TextStyle _valueStyle = TextStyle(
  color: AppColors.neutral900,
  fontSize: 14,
  height: 1.2,
);
const TextStyle _hintStyle = TextStyle(
  color: AppColors.neutral500,
  fontSize: 14,
  height: 1.2,
);

/// An editable text box (single- or multi-line).
class _TextBox extends StatelessWidget {
  const _TextBox({
    required this.controller,
    required this.hint,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return _Box(
      height: maxLines > 1 ? 80 : 40,
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        style: _valueStyle,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: hint,
          hintStyle: _hintStyle,
        ),
      ),
    );
  }
}

/// The live `n/max` character counter shown at the trailing edge of Nama Menu.
class _Counter extends StatelessWidget {
  const _Counter({required this.controller, required this.max});

  final TextEditingController controller;
  final int max;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => Text(
        '${value.text.length}/$max',
        style: const TextStyle(
          color: AppColors.neutral500,
          fontSize: 12,
          height: 1.2,
        ),
      ),
    );
  }
}

/// A display-only dropdown box (value or hint + chevron).
class _DropdownBox extends StatelessWidget {
  const _DropdownBox({required this.value, required this.hint});

  final String? value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return _Box(
      child: Row(
        children: [
          Expanded(
            child: Text(
              value ?? hint,
              style: value == null ? _hintStyle : _valueStyle,
            ),
          ),
          const Icon(
            ObraIcons.chevron_down,
            size: 20,
            color: AppColors.neutral500,
          ),
        ],
      ),
    );
  }
}

/// The `Harga` box: a grey `Rp` addon then the amount (value or hint).
class _PriceBox extends StatelessWidget {
  const _PriceBox({required this.value, required this.hint});

  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final empty = value.isEmpty;
    return _Box(
      padded: false,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.neutralTint,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(11)),
              border: Border(right: BorderSide(color: AppColors.neutral100)),
            ),
            alignment: Alignment.center,
            child: const Text('Rp', style: _valueStyle),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                empty ? hint : value,
                style: empty ? _hintStyle : _valueStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A discount-percentage box with a trailing `%` glyph.
class _PercentBox extends StatelessWidget {
  const _PercentBox({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return _Box(
      child: Row(
        children: [
          Expanded(child: Text(hint, style: _hintStyle)),
          const Text('%', style: _hintStyle),
        ],
      ),
    );
  }
}

/// A display-only date box with a trailing calendar glyph.
class _DateBox extends StatelessWidget {
  const _DateBox({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return _Box(
      child: Row(
        children: [
          Expanded(child: Text(hint, style: _hintStyle)),
          const Icon(
            ObraIcons.calendar_dates,
            size: 18,
            color: AppColors.neutral500,
          ),
        ],
      ),
    );
  }
}

/// The filled-state `Tag` box: a wrap of removable green chips.
class _TagBox extends StatelessWidget {
  const _TagBox({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return _Box(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final tag in tags) _TagChip(label: tag)],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successTint,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.success700,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            ObraIcons.circle_close_fill,
            size: 16,
            color: AppColors.successGreen,
          ),
        ],
      ),
    );
  }
}

/// An attached-variant row in the "Varian Menu" card (`varian-ditambahkan`): a
/// tinted list-icon tile, the variant name + option preview, and a chevron.
class _AttachedVariantRow extends StatelessWidget {
  const _AttachedVariantRow({required this.entry});

  final MenuVariantEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: AppColors.successTint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            ObraIcons.unordered_list,
            size: 20,
            color: AppColors.successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.name,
                style: const TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.optionsPreview,
                style: const TextStyle(
                  color: AppColors.neutral500,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          ObraIcons.chevron_right,
          size: 24,
          color: AppColors.neutral300,
        ),
      ],
    );
  }
}

/// The outlined green `Tambah Varian` button.
class _OutlinedGreenButton extends StatelessWidget {
  const _OutlinedGreenButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.successGreen),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                ObraIcons.add,
                size: 20,
                color: AppColors.successGreen,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

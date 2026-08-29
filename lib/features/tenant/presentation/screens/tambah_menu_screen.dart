import 'dart:async';

import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/utils/currency.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/app_toggle.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/tenant/data/models/product_category.dart';
import 'package:dtw_app/features/tenant/data/repositories/product_repository.dart';
import 'package:dtw_app/features/tenant/presentation/providers/menu_provider.dart';
import 'package:dtw_app/features/tenant/presentation/providers/variant_provider.dart';
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
/// `Tambah Varian` routes to [TenantRoutes.kelolaVarian]; variants picked
/// there land in [menuVariantSelectionProvider] and are attached to the new
/// product after it is created.
///
/// `Simpan Menu` really saves: `POST /v1/products` via [MenuList.create],
/// then `POST /v1/products/{id}/modifier-groups/sync` for any picked
/// variants, then the `berhasil-ditambahkan` success modal.
///
// TODO(open-question): the photo, Tag and Diskon fields have NO backing API
// (`POST /v1/products` accepts brand_id/category_id/sku/name/description/
// tags/price only, and nothing for discounts) so they stay display-only. The
// Populer (PIN) toggle likewise has no field to persist to. Validation here is
// only "required and non-zero" — the real per-field rules are unresolved.
class TambahMenuScreen extends ConsumerStatefulWidget {
  const TambahMenuScreen({
    this.prefilled = false,
    this.editingProductId,
    this.onBack,
    this.onSave,
    super.key,
  });

  /// Seeds the `menu-diisi` prototype frame (name/price/tags). Category is
  /// never seeded — real categories come from the API. Ignored when
  /// [editingProductId] is set, which loads real values instead.
  final bool prefilled;

  /// When set, this is the real "edit an existing menu" entry point: the form
  /// loads `GET /v1/products/{id}` plus its attached variants on open, and
  /// "Simpan Menu" calls `MenuList.updateProduct` instead of `.create`.
  ///
  /// Tapping a Menu Saya row used to open this form on the `menu-diisi`
  /// prototype seed — a hardcoded "Paket Komplit" — so every menu opened the
  /// same fake product.
  final String? editingProductId;

  /// Overrides the top-bar back action (used by the `varian-ditambahkan` route
  /// to return to `menu-berhasil-ditambahkan`). Falls back to `context.pop()`.
  final VoidCallback? onBack;

  /// Overrides "Simpan Menu" for prototype frame routes that only advance the
  /// flow. Null (the real entry points) does the real create.
  final VoidCallback? onSave;

  @override
  ConsumerState<TambahMenuScreen> createState() => _TambahMenuScreenState();
}

class _TambahMenuScreenState extends ConsumerState<TambahMenuScreen> {
  late final TextEditingController _name;
  late final TextEditingController _note;
  late final TextEditingController _price;

  /// The picked `category_id`. Required by `POST /v1/products`, so "Simpan
  /// Menu" stays blocked until one is chosen.
  String? _categoryId;

  bool _populer = false;
  bool _saving = false;
  String? _errorMessage;

  late bool _loading = widget.editingProductId != null;

  /// The edited product's brand-level active flag, carried through the PUT.
  bool _isActive = true;

  // Display-only: the `tambah-menu` tags and discount fields have no API
  // support at all (see the TODO above the class).
  late final List<String> _tags;

  @override
  void initState() {
    super.initState();
    // `prefilled` seeds the `menu-diisi` prototype frame. Category is NOT
    // seeded: the real categories come from the API and a hardcoded 'Nasi'
    // is not guaranteed to exist for this brand.
    _name = TextEditingController(
      text: widget.prefilled ? 'Paket Komplit' : '',
    );
    _price = TextEditingController(text: widget.prefilled ? '32.000' : '');
    _note = TextEditingController();
    _tags = widget.prefilled ? const ['Chicken', 'Combo Meal'] : const [];
    if (widget.editingProductId case final productId?) {
      unawaited(_loadForEditing(productId));
    }
  }

  /// Loads the product being edited, plus the variants already attached to it.
  ///
  /// The attached variants seed [menuVariantSelectionProvider] because
  /// `syncModifierGroups` is a full replace: if the form saved with an empty
  /// selection it would silently detach everything the product had.
  Future<void> _loadForEditing(String productId) async {
    final repository = ref.read(productRepositoryProvider);
    try {
      final product = await repository.fetchProduct(productId);
      // Best-effort: the attached variants are a display/pre-seed nicety, not
      // something the edit form is unusable without.
      List<VariantData> attached;
      try {
        final groups = await repository.fetchProductModifierGroups(productId);
        attached = [for (final g in groups) g.toVariantData()];
      } on Object {
        attached = const [];
      }
      if (!mounted) return;
      ref.read(menuVariantSelectionProvider.notifier).select(attached);
      setState(() {
        _name.text = product.name;
        _price.text = product.totalPrice.toString();
        _note.text = product.description ?? '';
        _categoryId = product.categoryId;
        _isActive = product.isActive;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = errorMessage(error);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (widget.onSave case final onSave?) {
      onSave();
      return;
    }

    final name = _name.text.trim();
    final categoryId = _categoryId;
    final price = parseRupiah(_price.text);

    final validationError = switch (null) {
      _ when name.isEmpty => 'Nama menu wajib diisi.',
      _ when categoryId == null => 'Kategori wajib dipilih.',
      _ when price <= 0 => 'Harga wajib diisi.',
      _ => null,
    };
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final String productId;
    try {
      if (widget.editingProductId case final editingId?) {
        await ref
            .read(menuListProvider.notifier)
            .updateProduct(
              editingId,
              name: name,
              categoryId: categoryId!,
              price: price,
              isActive: _isActive,
              description: _note.text.trim(),
            );
        productId = editingId;
      } else {
        productId = await ref
            .read(menuListProvider.notifier)
            .create(
              name: name,
              categoryId: categoryId!,
              price: price,
              description: _note.text.trim(),
            );
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = errorMessage(error);
      });
      return;
    }

    // Attaching the picked variants is a second call and deliberately
    // best-effort: the menu itself is already saved, so a failure here must
    // not read as "the menu wasn't created". It surfaces as a SnackBar and
    // leaves the menu in place with no variants attached.
    final variantIds = ref
        .read(menuVariantSelectionProvider)
        .map((v) => v.id)
        .toList();
    if (variantIds.isNotEmpty) {
      try {
        await ref
            .read(productRepositoryProvider)
            .syncModifierGroups(
              productId,
              modifierGroupIds: variantIds,
            );
      } on Object catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Menu tersimpan, varian gagal: '
              '${errorMessage(error)}',
            ),
          ),
        );
      }
    }

    if (!mounted) return;
    ref.read(menuVariantSelectionProvider.notifier).clear();
    final editing = widget.editingProductId != null;
    unawaited(
      showMenuSuccessModal(
        context,
        message: editing
            ? MenuSuccessModal.savedMessage
            : MenuSuccessModal.addedMessage,
        // `menu-berhasil-ditambahkan` is the post-ADD frame — its header
        // action becomes "+ Tambah Menu". An edit just returns to the list it
        // came from.
        onConfirm: () => editing && context.canPop()
            ? context.pop()
            : context.goNamed(TenantRoutes.menuBerhasil),
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
              title: widget.editingProductId == null
                  ? 'Tambah Menu'
                  : 'Ubah Menu',
              onBack:
                  widget.onBack ??
                  () => context.canPop() ? context.pop() : null,
            ),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
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
                      if (_errorMessage case final message?) ...[
                        const SizedBox(height: 12),
                        Text(
                          message,
                          style: const TextStyle(
                            color: AppColors.dangerRed,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: PrimaryButton(
                label: 'Simpan Menu',
                onPressed: _saving || _loading ? null : _save,
              ),
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
            child: _CategoryDropdown(
              value: _categoryId,
              onChanged: (id) => setState(() => _categoryId = id),
            ),
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'Harga',
            required: true,
            child: _PriceInput(
              controller: _price,
              hint: 'Contoh : 25.000',
            ),
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
    final variants = ref.watch(menuVariantSelectionProvider);
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
                '(${variants.length})',
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
          for (final variant in variants) ...[
            _AttachedVariantRow(variant: variant),
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
  const _TopBar({required this.title, required this.onBack});

  final String title;
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
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
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
/// tinted list-icon tile, the variant name + option summary, and a chevron.
class _AttachedVariantRow extends StatelessWidget {
  const _AttachedVariantRow({required this.variant});

  final VariantData variant;

  /// The option names when known, otherwise the count. A variant picked from
  /// `GET /v1/modifier-groups` knows `option_count` but not the names.
  String get _summary => variant.optionNames.isEmpty
      ? '${variant.optionCount} Opsi'
      : variant.optionNames.join(', ');

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
                variant.name,
                style: const TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _summary,
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

/// The real `Kategori` dropdown, backed by [productCategoriesProvider]
/// (`GET /v1/product-categories`). `POST /v1/products` requires a
/// `category_id`, so this is the one dropdown on this form that had to become
/// interactive.
///
/// Renders inside the same [_Box] as the display-only fields so the form stays
/// visually uniform, and degrades to an inline message while loading or when
/// the fetch fails — the form is unusable without a category either way.
class _CategoryDropdown extends ConsumerWidget {
  const _CategoryDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(productCategoriesProvider);

    return categoriesAsync.when(
      loading: () => const _Box(
        child: Text('Memuat kategori...', style: _hintStyle),
      ),
      error: (error, _) => _Box(
        child: Text(errorMessage(error), style: _hintStyle),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return const _Box(
            child: Text('Belum ada kategori.', style: _hintStyle),
          );
        }
        return _Box(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              hint: const Text('Pilih Kategori', style: _hintStyle),
              icon: const Icon(
                ObraIcons.chevron_down,
                size: 20,
                color: AppColors.neutral500,
              ),
              style: _valueStyle,
              onChanged: onChanged,
              items: [
                for (final ProductCategory category in categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name, style: _valueStyle),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The editable `Harga` field: a grey `Rp` addon then a numeric entry.
///
/// Digits only — the value is parsed with `parseRupiah`, so the tenant may
/// type `25.000` or `25000` and both mean 25000.
class _PriceInput extends StatelessWidget {
  const _PriceInput({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
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
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: _valueStyle,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: hint,
                  hintStyle: _hintStyle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

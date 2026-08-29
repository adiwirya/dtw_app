import 'dart:async';

import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/tenant/data/repositories/modifier_group_repository.dart';
import 'package:dtw_app/features/tenant/presentation/providers/variant_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/opsi_varian_modal.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/variant_rows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obra_icons/obra_icons.dart';

/// The add-variant / fill-variant form (`tambah-varian-2` empty, `varian-diisi`
/// filled, `tambah-opsi-2` with one option, `opsi-2-ditambahkan` with two).
///
/// A "Nama Varian" input, the L6 "Aturan Pilihan" card holding the two rule
/// toggles — **Wajib Dipilih** (required) and **Pilih Lebih dari Satu**
/// (multi-select) via [VariantRuleToggleRow] — and an "Opsi Varian" card that
/// either shows the "Belum ada opsi" empty state or the added [options] as
/// [VariantOptionRow]s (each with its `Gratis` / `+price` add-on, L6). The
/// "+ Tambah Opsi" action opens the option modal ([showOpsiVarianModal] /
/// `opsi-varian-1`).
///
/// "Simpan Varian" always shows: when [onSave] is provided (the prototype
/// frame routes) it defers to that callback as before; otherwise it does the
/// real save — `VariantList.create` for a new variant, or `VariantList.update`
/// when [editingVariantId] is set (`varian-diisi`, reached by tapping an
/// existing variant on `kelola-varian`) — and pops back on success.
///
/// Editing loads the real variant (`GET /v1/modifier-groups/{id}`) before
/// showing the form. There is no delete endpoint for an option once saved
/// (confirmed live — see `ModifierGroupRepository.updateOption`), so the
/// remove button on an option row only shows for options added in the
/// current session ([VariantOptionData.id] still null) — an already-saved
/// option can be renamed/repriced but not removed.
///
// TODO(open-question): server-side name/option validation rules (beyond
// "non-empty") are still an unresolved Open Question.
class TambahVarianScreen extends ConsumerStatefulWidget {
  const TambahVarianScreen({
    this.prefilled = false,
    this.options = const [],
    this.onSave,
    this.onTambahOpsi,
    this.editingVariantId,
    super.key,
  });

  /// Seeds the `varian-diisi` filled state (name populated with "Ukuran
  /// Minuman") for the prototype frame route. Ignored when
  /// [editingVariantId] is set, since that loads the real name instead.
  final bool prefilled;

  /// Options already attached to the variant, rendered as [VariantOptionRow]s
  /// with the reorder handle + remove button (`tambah-opsi-2` /
  /// `opsi-2-ditambahkan`). Empty => the "Belum ada opsi" placeholder.
  final List<VariantOptionData> options;

  /// Overrides "Simpan Varian" for the prototype frame routes, which advance
  /// to the next hardcoded frame instead of saving for real. Null (the real
  /// `tambah-varian-2` / `varian-diisi` entry points) does the real save.
  final VoidCallback? onSave;

  /// "+ Tambah Opsi" handler. Null falls back to opening [showOpsiVarianModal]
  /// and appending the entered option to this form's local list.
  final void Function(BuildContext context)? onTambahOpsi;

  /// When set, this is the real "edit an existing variant" entry point: the
  /// form loads `GET /v1/modifier-groups/{editingVariantId}` on open and
  /// "Simpan Varian" calls `VariantList.update` instead of `.create`.
  final String? editingVariantId;

  @override
  ConsumerState<TambahVarianScreen> createState() =>
      _TambahVarianScreenState();
}

class _TambahVarianScreenState extends ConsumerState<TambahVarianScreen> {
  late final TextEditingController _name;
  late List<VariantOptionData> _options;

  /// A stable key per option row, so `ReorderableListView` tracks rows across
  /// a drag. Option ids can't serve: an option added in this session has none
  /// until its POST returns, and two options may share a name.
  late List<int> _optionKeys;
  int _nextOptionKey = 0;
  bool _required = false;
  bool _multiSelect = false;
  bool _saving = false;
  late bool _loading = widget.editingVariantId != null;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: widget.prefilled ? 'Ukuran Minuman' : '',
    );
    _setOptions(List.of(widget.options));
    if (widget.editingVariantId case final groupId?) {
      unawaited(_loadForEditing(groupId));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Replaces the option list and re-issues its row keys.
  void _setOptions(List<VariantOptionData> options) {
    _options = options;
    _optionKeys = [for (final _ in options) _nextOptionKey++];
  }

  /// `onReorderItem` (unlike the deprecated `onReorder`) already accounts for
  /// the dragged row being lifted out, so [newIndex] is the final position.
  void _onReorderItem(int oldIndex, int newIndex) {
    setState(() {
      _options.insert(newIndex, _options.removeAt(oldIndex));
      _optionKeys.insert(newIndex, _optionKeys.removeAt(oldIndex));
    });
  }

  Future<void> _loadForEditing(String groupId) async {
    try {
      final group = await ref
          .read(modifierGroupRepositoryProvider)
          .fetchModifierGroup(groupId);
      if (!mounted) return;
      setState(() {
        _name.text = group.name;
        _required = group.isRequired;
        _multiSelect = group.type == VariantType.ganda;
        _setOptions(group.options ?? []);
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

  void _handleTambahOpsi() {
    final handler = widget.onTambahOpsi;
    if (handler != null) {
      handler(context);
      return;
    }
    // Default (standalone) behaviour: open the option modal; on Simpan just
    // append the entered option to the local list.
    unawaited(
      showOpsiVarianModal(context).then((option) {
        if (option != null && option.name.isNotEmpty && mounted) {
          setState(() {
            _options = [..._options, option];
            _optionKeys = [..._optionKeys, _nextOptionKey++];
          });
        }
      }),
    );
  }

  Future<void> _handleSimpanVarian() async {
    if (widget.onSave case final onSave?) {
      onSave();
      return;
    }

    final name = _name.text.trim();
    if (name.isEmpty || _options.isEmpty) {
      setState(
        () => _errorMessage = name.isEmpty
            ? 'Nama varian wajib diisi.'
            : 'Tambahkan minimal satu opsi.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      if (widget.editingVariantId case final groupId?) {
        await ref.read(variantListProvider.notifier).updateVariant(
              groupId: groupId,
              name: name,
              isRequired: _required,
              multiSelect: _multiSelect,
              options: _options,
            );
      } else {
        await ref.read(variantListProvider.notifier).create(
              name: name,
              isRequired: _required,
              multiSelect: _multiSelect,
              options: _options,
            );
      }
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = errorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _namaField(),
                          const SizedBox(height: 16),
                          _aturanCard(),
                          const SizedBox(height: 16),
                          _opsiCard(),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PrimaryButton(
                label: 'Simpan Varian',
                onPressed: _saving ? null : _handleSimpanVarian,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _namaField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nama Varian',
              style: TextStyle(
                color: AppColors.neutral900,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                color: AppColors.dangerRed,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppInput(controller: _name, hintText: 'Contoh : Tingkat Pedas'),
      ],
    );
  }

  // L6: the two-toggle "Aturan Pilihan" card (required + multi-select).
  Widget _aturanCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Aturan Pilihan',
            style: TextStyle(
              color: AppColors.neutral900,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          VariantRuleToggleRow(
            title: 'Wajib Dipilih',
            subtitle: 'Pelanggan harus memilih salah satu opsi',
            value: _required,
            onChanged: (v) => setState(() => _required = v),
          ),
          const SizedBox(height: 16),
          VariantRuleToggleRow(
            title: 'Pilih Lebih dari Satu',
            subtitle: 'Pelanggan dapat memilih beberapa opsi',
            value: _multiSelect,
            onChanged: (v) => setState(() => _multiSelect = v),
          ),
        ],
      ),
    );
  }

  Widget _opsiCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Opsi Varian',
            style: TextStyle(
              color: AppColors.neutral900,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          if (_options.isEmpty) ...[
            const Text(
              'Belum ada opsi',
              style: TextStyle(
                color: AppColors.neutral300,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tambahkan opsi yang bisa dipilih customer',
              style: TextStyle(
                color: AppColors.neutral300,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            // The drag handle on each row is a real
            // `ReorderableDragStartListener` now — the caption below used to
            // promise reordering that nothing implemented.
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _options.length,
              onReorderItem: _onReorderItem,
              itemBuilder: (context, i) => Padding(
                key: ValueKey(_optionKeys[i]),
                padding: const EdgeInsets.only(bottom: 8),
                child: VariantOptionRow(
                  data: _options[i],
                  dragIndex: i,
                  onRemove: _options[i].id == null
                      ? () => setState(() {
                          _options.removeAt(i);
                          _optionKeys.removeAt(i);
                        })
                      : null,
                ),
              ),
            ),
            const Center(
              child: Text(
                'Geser untuk mengubah urutan opsi',
                style: TextStyle(
                  color: AppColors.neutral300,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _TambahOpsiButton(
            // Prototype: the variant form's "+ Tambah Opsi" opens the option
            // modal (`opsi-varian-1`); its Simpan advances the option flow.
            onTap: _handleTambahOpsi,
          ),
        ],
      ),
    );
  }
}

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
            InkResponse(
              onTap: onBack,
              radius: 20,
              child: const Icon(
                ObraIcons.arrow_left,
                size: 24,
                color: AppColors.neutral900,
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'Tambah Varian',
                  style: TextStyle(
                    color: AppColors.neutral900,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}

/// White rounded section card matching the tenant menu-form card style.
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

/// The centered green "+ Tambah Opsi" text action inside the Opsi Varian card.
class _TambahOpsiButton extends StatelessWidget {
  const _TambahOpsiButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ObraIcons.add, size: 20, color: AppColors.successGreen),
            SizedBox(width: 8),
            Text(
              'Tambah Opsi',
              style: TextStyle(
                color: AppColors.successGreen,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

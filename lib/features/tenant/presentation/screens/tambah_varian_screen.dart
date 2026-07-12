import 'dart:async';

import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/opsi_varian_modal.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/variant_rows.dart';
import 'package:flutter/material.dart';
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
/// `opsi-varian-1`); when [onSave] is provided a bottom "Simpan Varian" button
/// is shown (the `tambah-opsi-2` / `opsi-2-ditambahkan` frames).
///
// TODO(open-question): the variant data source + validation rules are
// unresolved Open Questions; save / option attachment are UI-only mocks.
class TambahVarianScreen extends StatefulWidget {
  const TambahVarianScreen({
    this.prefilled = false,
    this.options = const [],
    this.onSave,
    this.onTambahOpsi,
    super.key,
  });

  /// Seeds the `varian-diisi` filled state (name populated with "Ukuran
  /// Minuman").
  final bool prefilled;

  /// Options already attached to the variant, rendered as [VariantOptionRow]s
  /// with the reorder handle + remove button (`tambah-opsi-2` /
  /// `opsi-2-ditambahkan`). Empty => the "Belum ada opsi" placeholder.
  final List<VariantOptionData> options;

  /// Bottom "Simpan Varian" handler. Null hides the button (the plain
  /// `tambah-varian-2` / `varian-diisi` frames have no bottom button here).
  final VoidCallback? onSave;

  /// "+ Tambah Opsi" handler. Null falls back to opening [showOpsiVarianModal]
  /// (a self-contained mock that just closes on Simpan).
  final void Function(BuildContext context)? onTambahOpsi;

  @override
  State<TambahVarianScreen> createState() => _TambahVarianScreenState();
}

class _TambahVarianScreenState extends State<TambahVarianScreen> {
  late final TextEditingController _name;
  late List<VariantOptionData> _options;
  bool _required = false;
  bool _multiSelect = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: widget.prefilled ? 'Ukuran Minuman' : '',
    );
    _options = List.of(widget.options);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _handleTambahOpsi() {
    final handler = widget.onTambahOpsi;
    if (handler != null) {
      handler(context);
      return;
    }
    // Default (standalone) behaviour: open the option modal; on Simpan just
    // append the entered option to the local list (UI-only mock).
    unawaited(
      showOpsiVarianModal(context).then((option) {
        if (option != null && option.name.isNotEmpty && mounted) {
          setState(() => _options = [..._options, option]);
        }
      }),
    );
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _namaField(),
                    const SizedBox(height: 16),
                    _aturanCard(),
                    const SizedBox(height: 16),
                    _opsiCard(),
                  ],
                ),
              ),
            ),
            if (widget.onSave != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: PrimaryButton(
                  label: 'Simpan Varian',
                  onPressed: widget.onSave,
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
            for (var i = 0; i < _options.length; i++) ...[
              VariantOptionRow(
                data: _options[i],
                onRemove: () => setState(() => _options.removeAt(i)),
              ),
              const SizedBox(height: 8),
            ],
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

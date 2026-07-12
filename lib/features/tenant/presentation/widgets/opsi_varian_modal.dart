import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/variant_rows.dart';
import 'package:flutter/material.dart';

/// The 358×262 "Opsi & Customisasi" option add/edit card (`opsi-varian-1`,
/// `-1-diisi`, `-2-diisi`, `-2-diisi-2`).
///
/// A white 16-radius card with a "Nama Opsi" text field and a "Harga
/// (Optional)" number field carrying a leading grey **"Rp"** add-on (L6: each
/// option of a required + multi-select variant has a "+price" add-on), then a
/// green "Simpan" button.
///
/// [onSave] receives the entered [VariantOptionData] (the price is formatted to
/// `RpN.NNN` when non-zero, else null => `Gratis`). Presented as a dialog via
/// [showOpsiVarianModal]; also embeddable directly (golden tests pump it at its
/// 358 design width).
///
// TODO(open-question): option data + price validation are unresolved Open
// Questions; this is UI-only (no persistence, no numeric validation beyond
// stripping non-digits).
class OpsiVarianModal extends StatefulWidget {
  const OpsiVarianModal({
    this.initialName = '',
    this.initialPrice = '',
    this.onSave,
    super.key,
  });

  /// Seeds the "Nama Opsi" field (e.g. `Small` / `Medium` on the filled frames).
  final String initialName;

  /// Seeds the "Harga" field digits (e.g. `0` / `3000` on the filled frames).
  final String initialPrice;

  /// Called with the entered option when "Simpan" is tapped.
  final ValueChanged<VariantOptionData>? onSave;

  @override
  State<OpsiVarianModal> createState() => _OpsiVarianModalState();
}

class _OpsiVarianModalState extends State<OpsiVarianModal> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  late final TextEditingController _price = TextEditingController(
    text: widget.initialPrice,
  );

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  /// Turns the raw price digits into the [VariantOptionData] add-on string:
  /// blank / `0` => null (`Gratis`); otherwise `Rp<grouped digits>`.
  VariantOptionData _asOption() {
    final digits = _price.text.replaceAll(RegExp('[^0-9]'), '');
    final value = int.tryParse(digits) ?? 0;
    return VariantOptionData(
      name: _name.text.trim(),
      addonPrice: value == 0 ? null : 'Rp${_group(value)}',
    );
  }

  /// Thousands-separated digits (`3000` -> `3.000`) matching the references.
  static String _group(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i != 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 358,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Opsi & Customisasi',
              style: TextStyle(
                color: AppColors.neutral900,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Nama Opsi'),
            const SizedBox(height: 8),
            _NamaField(controller: _name),
            const SizedBox(height: 8),
            const _FieldLabel(label: 'Harga', hint: 'Optional'),
            const SizedBox(height: 8),
            _HargaField(controller: _price),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Simpan',
              onPressed: () => widget.onSave?.call(_asOption()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Presents [OpsiVarianModal] as a centered dialog; resolves with the entered
/// [VariantOptionData] on "Simpan", or null when dismissed.
Future<VariantOptionData?> showOpsiVarianModal(
  BuildContext context, {
  String initialName = '',
  String initialPrice = '',
}) {
  return showDialog<VariantOptionData>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      child: OpsiVarianModal(
        initialName: initialName,
        initialPrice: initialPrice,
        onSave: (option) => Navigator.of(context).pop(option),
      ),
    ),
  );
}

/// "Label" + optional grey "(hint)" row above a field (`Atom/Label`).
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.hint});

  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.neutral900,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(width: 4),
          Text(
            '($hint)',
            style: const TextStyle(
              color: AppColors.neutral500,
              fontSize: 14,
              height: 1,
            ),
          ),
        ],
      ],
    );
  }
}

/// The "Nama Opsi" 40px text field (mirrors the shared AppInput box styling).
class _NamaField extends StatelessWidget {
  const _NamaField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral100),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: AppColors.neutral900,
          fontSize: 14,
          height: 1,
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: 'Contoh : Level 1',
          hintStyle: TextStyle(
            color: AppColors.neutral500,
            fontSize: 14,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// The "Harga" number field with a leading grey "Rp" add-on box.
class _HargaField extends StatelessWidget {
  const _HargaField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: radius,
        border: Border.all(color: AppColors.neutral100),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(
            width: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.neutralTint,
              border: Border(
                right: BorderSide(color: AppColors.neutral100),
              ),
            ),
            child: const Text(
              'Rp',
              style: TextStyle(
                color: AppColors.neutral900,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 14,
                  height: 1,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Contoh : 5000',
                  hintStyle: TextStyle(
                    color: AppColors.neutral500,
                    fontSize: 14,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

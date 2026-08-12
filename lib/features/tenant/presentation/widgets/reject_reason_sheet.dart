import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/app_input.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter/material.dart';

/// A preset rejection reason offered on the `alasan-penolakan` modal.
enum RejectReasonOption {
  stokHabis('Stok Habis', 'Stok saat ini sudah habis'),
  bahanTidakTersedia('Bahan tidak tersedia', 'Bahan utama tidak tersedia');

  const RejectReasonOption(this.title, this.subtitle);

  /// Bold option title, e.g. `Stok Habis`.
  final String title;

  /// Muted supporting line under the title.
  final String subtitle;
}

/// Presents the `alasan-penolakan` reason-capture as a bottom sheet and
/// completes with the chosen reason text, or null if dismissed.
///
/// The sheet reproduces the modal frame (rounded-top white card): the rejected
/// [item] summary, two preset [RejectReasonOption] radios and an "Alasan
/// Lainnya" free-text field, saved with the "Simpan Alasan" CTA.
Future<String?> showRejectReasonSheet(
  BuildContext context, {
  required OrderLineItem item,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: RejectReasonSheet(item: item),
    ),
  );
}

/// The `alasan-penolakan` modal body. Public so it can be pumped directly in
/// golden tests and reused by the `/order/alasan-penolakan` route.
class RejectReasonSheet extends StatefulWidget {
  const RejectReasonSheet({required this.item, super.key});

  /// The item being rejected — rendered in the summary card at the top.
  final OrderLineItem item;

  @override
  State<RejectReasonSheet> createState() => _RejectReasonSheetState();
}

class _RejectReasonSheetState extends State<RejectReasonSheet> {
  RejectReasonOption? _selected;
  final TextEditingController _other = TextEditingController();

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  String? get _resolvedReason {
    final custom = _other.text.trim();
    if (custom.isNotEmpty) return custom;
    return _selected?.title;
  }

  bool get _canSave => _resolvedReason != null;

  void _save() {
    final reason = _resolvedReason;
    if (reason == null) return;
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 16),
          _ReasonItemCard(item: widget.item),
          const SizedBox(height: 16),
          const Text(
            'Pilih Alasan',
            style: TextStyle(
              color: AppColors.neutral900,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          for (final option in RejectReasonOption.values) ...[
            RejectReasonOptionRow(
              option: option,
              selected: _selected == option,
              onTap: () => setState(() => _selected = option),
            ),
            const SizedBox(height: 12),
          ],
          RejectOtherReasonField(
            controller: _other,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Simpan Alasan',
            onPressed: _canSave ? _save : null,
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Alasan Menolak Item',
            style: TextStyle(
              color: AppColors.neutral900,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(
            // TODO(open-question): Material glyph until flutter_svg / the cache
            // icon set is a dependency (mirrors OrderDetail / SuccessModal).
            Icons.close,
            size: 24,
            color: AppColors.neutral900,
          ),
        ),
      ],
    );
  }
}

/// The compact item summary at the top of the reason modal (`Component 28`):
/// 50px thumbnail + name + `Qty : N` + green price.
class _ReasonItemCard extends StatelessWidget {
  const _ReasonItemCard({required this.item});

  final OrderLineItem item;

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
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.neutralTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.image_outlined,
              color: AppColors.neutral300,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: AppColors.neutral900,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty : ${item.qty}',
                  style: const TextStyle(
                    color: AppColors.neutral500,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.price,
                  style: const TextStyle(
                    color: AppColors.successGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One radio row: a circular selector + title/subtitle.
/// One selectable preset reason (radio + title + subtitle).
///
/// Public so `TenantRejectOrderScreen` can render the same preset list inline
/// for a whole-order cancellation instead of duplicating the styling.
class RejectReasonOptionRow extends StatelessWidget {
  const RejectReasonOptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final RejectReasonOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _radio(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.title,
                    style: const TextStyle(
                      color: AppColors.neutral900,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    style: const TextStyle(
                      color: AppColors.neutral500,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _radio() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.successGreen : AppColors.neutral300,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.successGreen,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

/// The "Alasan Lainnya" labelled free-text field.
///
/// Public because `TenantRejectOrderScreen` captures a whole-order
/// cancellation reason inline (no sheet) and must offer the same field.
class RejectOtherReasonField extends StatelessWidget {
  const RejectOtherReasonField({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppInput(
      controller: controller,
      onChanged: onChanged,
      label: 'Alasan Lainnya',
      hintText: 'Masukkan alasan lainnya',
    );
  }
}

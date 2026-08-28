import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';

/// One row of the [SuccessModal] detail card: a tinted 30x30 icon tile followed
/// by a small label and a bold value.
///
/// The value is plain text so callers can inline a dot separator, e.g.
/// `'Meja A-12  •  Downtown'` — matching the exported design.
@immutable
class SuccessModalDetail {
  const SuccessModalDetail({
    required this.icon,
    required this.label,
    required this.value,
    this.tileColor,
    this.iconColor,
  });

  /// Glyph rendered inside the icon tile.
  ///
  // TODO(open-question): the design uses Lucide-style SVGs (store / armchair /
  // user-round / timer); this reuses Material glyphs like the rest of the app
  // (see OrderCard) until flutter_svg / the icon set is a dependency.
  final IconData icon;

  /// Muted caption above the value, e.g. `Dari Tenant`.
  final String label;

  /// Emphasised value line, e.g. `KFC Fried Chicken`.
  final String value;

  /// Icon-tile background. Defaults to the success tint.
  final Color? tileColor;

  /// Icon color. Defaults to the success green.
  final Color? iconColor;
}

/// Presents the shared "berhasil ditambahkan" success modal as a centered,
/// dismissible dialog and completes when it is closed.
///
/// The modal itself never navigates — [onConfirm] is invoked (after the dialog
/// pops) so the caller decides the destination. This is what lets the same
/// widget back both success frames (`berhasil-ditambahkan` →
/// `menu-order-antar`, `berhasil-ditambahkan-2` → `menu-order-selesai`).
Future<void> showSuccessModal(
  BuildContext context, {
  required VoidCallback onConfirm,
  required List<SuccessModalDetail> details,
  String title = SuccessModal.defaultTitle,
  String message = SuccessModal.defaultMessage,
  String confirmLabel = SuccessModal.defaultConfirmLabel,
  bool barrierDismissible = true,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => SuccessModal(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      details: details,
      onConfirm: onConfirm,
    ),
  );
}

/// The reusable success/confirmation modal shown after an order action.
///
/// Rendered as a centered [Dialog] (the exported frame is a centered 358x426
/// overlay, not anchored to an edge → a dialog, not a bottom sheet). Prefer the
/// [showSuccessModal] helper; this widget is public so it can be pumped
/// directly in tests and reused inside a custom presentation if needed.
///
/// Cached design values (`berhasil-ditambahkan` / `-2`): 358 wide, 16 radius,
/// white surface, 24 padding + 24 section gaps, 80x80 check ring, title
/// Open Sans Bold 24 `#2B2F38`, message Open Sans Regular 14 `#667085`, a white
/// 12-radius detail card (shadow `0 2 16 rgba(6,51,54,0.10)`) of 30x30 icon
/// tiles, and a full-width success-green pill CTA ([PrimaryButton]).
class SuccessModal extends StatelessWidget {
  const SuccessModal({
    required this.onConfirm,
    required this.details,
    this.title = defaultTitle,
    this.message = defaultMessage,
    this.confirmLabel = defaultConfirmLabel,
    super.key,
  });

  /// Design default heading (`berhasil-ditambahkan` frame).
  static const String defaultTitle = 'Tugas Berhasil Diambil!';

  /// Design default sub-heading (`berhasil-ditambahkan` frame).
  static const String defaultMessage = 'Silahkan antar pesanan ke meja tujuan';

  /// Design default CTA label (`berhasil-ditambahkan` frame).
  static const String defaultConfirmLabel = 'Mengerti';

  /// Heading, e.g. `Tugas Berhasil Diambil!`.
  final String title;

  /// Sub-heading below the title.
  final String message;

  /// CTA label on the confirm button.
  final String confirmLabel;

  /// Invoked when the CTA is tapped. The dialog is popped first, then this runs
  /// — the caller owns navigation. The modal never routes on its own.
  final VoidCallback onConfirm;

  /// The rows describing the order this modal is confirming.
  ///
  /// Required, deliberately. These used to be optional with a fallback to a
  /// hardcoded sample of the Figma frame's own copy (KFC Fried Chicken / Meja
  /// A-12 / Budi Santoso). A caller that forgot to pass `details` then showed
  /// the user a confirmation for an order that did not exist — which is
  /// exactly what happened on the busboy "Ambil Pesanan" flow. There is no
  /// safe default for "which order was this", so there is no default.
  final List<SuccessModalDetail> details;

  // --- Cached design tokens ------------------------------------------------

  static const double _width = 358;
  static const double _radius = 16;
  static const double _pad = 24;
  static const double _sectionGap = 24;
  static const double _ring = 80;
  static const double _cardRadius = 12;
  static const double _cardPad = 12;
  static const double _rowGap = 16;
  static const double _tile = 30;
  static const double _tileRadius = 8;
  static const double _icon = 16;

  // TODO(open-question): family is Open Sans in the cache; the app doesn't
  // bundle it yet, so these use the default family (see [PrimaryButton]).
  static const TextStyle _titleStyle = TextStyle(
    color: AppColors.neutral900,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );
  static const TextStyle _messageStyle = TextStyle(
    color: AppColors.neutral500,
    fontSize: 14,
    height: 1.3,
  );
  static const TextStyle _labelStyle = TextStyle(
    color: AppColors.neutral500,
    fontSize: 12,
    height: 1.2,
  );
  static const TextStyle _valueStyle = TextStyle(
    color: AppColors.neutral900,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: SizedBox(
        width: _width,
        child: Padding(
          padding: const EdgeInsets.all(_pad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _checkRing(),
              const SizedBox(height: _sectionGap),
              _titleBlock(),
              const SizedBox(height: _sectionGap),
              PrimaryButton(
                label: confirmLabel,
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkRing() {
    return Container(
      width: _ring,
      height: _ring,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.successGreen.withValues(alpha: 0.5),
          width: 4,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.check_rounded,
          size: 40,
          color: AppColors.successGreen,
        ),
      ),
    );
  }

  Widget _titleBlock() {
    return Column(
      children: [
        // Title + message block.
        Text(title, style: _titleStyle, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(message, style: _messageStyle, textAlign: TextAlign.center),
        const SizedBox(height: _rowGap),
        _detailCard(),
      ],
    );
  }

  Widget _detailCard() {
    final rows = <Widget>[];
    final items = details;
    for (var i = 0; i < items.length; i++) {
      if (i > 0) rows.add(const SizedBox(height: _rowGap));
      rows.add(_detailRow(items[i]));
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: const Color(0xFFEFF1F4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A063336), // rgba(6,51,54,0.10)
            offset: Offset(0, 2),
            blurRadius: 16,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(_cardPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        ),
      ),
    );
  }

  Widget _detailRow(SuccessModalDetail detail) {
    return Row(
      children: [
        _iconTile(detail),
        const SizedBox(width: _cardPad),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(detail.label, style: _labelStyle),
              Text(detail.value, style: _valueStyle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconTile(SuccessModalDetail detail) {
    return Container(
      width: _tile,
      height: _tile,
      decoration: BoxDecoration(
        color: detail.tileColor ?? AppColors.successTint,
        borderRadius: BorderRadius.circular(_tileRadius),
      ),
      child: Center(
        child: Icon(
          detail.icon,
          size: _icon,
          color: detail.iconColor ?? AppColors.successGreen,
        ),
      ),
    );
  }
}

import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/success_modal.dart';
import 'package:flutter/material.dart';

/// Presents the `berhasil-ditambahkan-2` rejection-confirmed frame.
///
/// This frame is just the shared [SuccessModal] with tenant-specific copy and
/// an accepted-vs-rejected breakdown rendered as [SuccessModalDetail] rows, so
/// it reuses [showSuccessModal] instead of re-implementing the dialog + check
/// ring. Like the shared modal it never navigates itself — [onConfirm] runs
/// after the dialog pops so the caller owns the destination (the prototype
/// lands on `pesanan-diproses`).
Future<void> showRejectConfirmedModal(
  BuildContext context, {
  required VoidCallback onConfirm,
  required int acceptedCount,
  required int rejectedCount,
  required String acceptedTotal,
  bool barrierDismissible = true,
}) {
  return showSuccessModal(
    context,
    onConfirm: onConfirm,
    title: RejectConfirmedModal.title,
    message: RejectConfirmedModal.message,
    confirmLabel: RejectConfirmedModal.confirmLabel,
    details: RejectConfirmedModal.detailsFor(
      acceptedCount: acceptedCount,
      rejectedCount: rejectedCount,
      acceptedTotal: acceptedTotal,
    ),
    barrierDismissible: barrierDismissible,
  );
}

/// Thin wrapper over [SuccessModal] for the `berhasil-ditambahkan-2` frame:
/// "Pesanan dikonfirmasi" title over a card that breaks down accepted vs.
/// rejected items and the accepted total, above a full-width
/// "Konfirmasi Pesanan" CTA.
///
/// Public so it can be pumped directly in golden tests; production code should
/// prefer [showRejectConfirmedModal].
class RejectConfirmedModal extends StatelessWidget {
  const RejectConfirmedModal({
    required this.onConfirm,
    required this.acceptedCount,
    required this.rejectedCount,
    required this.acceptedTotal,
    super.key,
  });

  /// Invoked after the dialog pops. The modal never routes on its own.
  final VoidCallback onConfirm;

  /// Number of accepted (available) items.
  final int acceptedCount;

  /// Number of rejected (unavailable) items.
  final int rejectedCount;

  /// Pre-formatted accepted total, e.g. `Rp35.000`.
  final String acceptedTotal;

  /// Heading of the rejection-confirmed frame.
  static const String title = 'Pesanan dikonfirmasi';

  /// Sub-heading below the title.
  static const String message = 'Pesanan akan diteruskan ke customer';

  /// CTA label.
  static const String confirmLabel = 'Konfirmasi Pesanan';

  /// Maps the accepted/rejected breakdown onto [SuccessModal] detail rows: an
  /// accepted line, a rejected line, and the accepted total.
  static List<SuccessModalDetail> detailsFor({
    required int acceptedCount,
    required int rejectedCount,
    required String acceptedTotal,
  }) {
    return [
      SuccessModalDetail(
        icon: Icons.check_rounded,
        label: 'Tersedia',
        value: '$acceptedCount item diterima',
        tileColor: AppColors.successTint,
        iconColor: AppColors.successGreen,
      ),
      SuccessModalDetail(
        icon: Icons.close_rounded,
        label: 'Tidak tersedia',
        value: '$rejectedCount item ditolak',
        tileColor: AppColors.dangerTint,
        iconColor: AppColors.dangerRed,
      ),
      SuccessModalDetail(
        icon: Icons.payments_outlined,
        label: 'Total diterima',
        value: acceptedTotal,
        tileColor: AppColors.successTint,
        iconColor: AppColors.successGreen,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SuccessModal(
      onConfirm: onConfirm,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      details: detailsFor(
        acceptedCount: acceptedCount,
        rejectedCount: rejectedCount,
        acceptedTotal: acceptedTotal,
      ),
    );
  }
}

import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/utils/currency.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/core/widgets/success_modal.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_order_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/reject_reason_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

export 'package:dtw_app/core/utils/currency.dart' show formatRupiah;

/// Indonesian month names for [_formatOrderDateTime]. A three-line lookup
/// instead of an `intl` dependency, matching how `formatRupiah` hand-rolls
/// currency formatting rather than pulling `NumberFormat` in.
const List<String> _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// Renders `10 Mei 2024 10:36 WIB` for the order-info row.
///
/// The API returns Jakarta-local naive timestamps (`2026-08-07 09:24:08`),
/// which [TenantOrder.fromJson] parses as-is — so the WIB suffix labels what
/// the value already is rather than converting anything.
String _formatOrderDateTime(DateTime at) {
  final hh = at.hour.toString().padLeft(2, '0');
  final mm = at.minute.toString().padLeft(2, '0');
  return '${at.day} ${_monthNames[at.month - 1]} ${at.year} $hh:$mm WIB';
}

/// The `pesanan-ditolak` / `konfirmasi-pesanan` screen: the tenant picks a
/// reason and confirms that an incoming order is rejected.
///
/// **All-or-nothing, deliberately.** This screen used to let the tenant toggle
/// individual items as unavailable, with copy promising "Pelanggan tetap akan
/// menerima item yang tersedia". The API supports no such thing — the only
/// rejection it offers is cancelling the whole order (`PATCH
/// /v1/orders/{id}/status` -> `CANCELLED`; see [TenantOrderBoard.reject]), and
/// nothing ever transmitted the per-item selection. Promising partial
/// fulfillment the backend cannot deliver is worse than not offering it, so
/// the toggles are gone and this screen captures one cancellation reason for
/// the order as a unit. Restore per-item selection only once the backend
/// confirms it supports partial-item rejection.
///
/// Every value shown is read off the real [tenantOrderBoardProvider] entry for
/// [orderId] — there is no seeded order data here.
class TenantRejectOrderScreen extends ConsumerStatefulWidget {
  const TenantRejectOrderScreen({
    required this.orderId,
    this.initialReason,
    super.key,
  });

  /// Id of the order to reject.
  ///
  /// Required, and deliberately never defaulted. A placeholder default (it was
  /// `'92842'`) meant a caller that forgot to thread the real id still
  /// rendered and still ran the confirm flow — against an order id that
  /// matched nothing on the board, so the rejection silently no-oped while the
  /// tenant was shown success feedback.
  final String orderId;

  /// Pre-selects a reason. Only the `konfirmasi-pesanan` deep link uses it, to
  /// render this screen's reason-chosen state for that prototype frame.
  final String? initialReason;

  @override
  ConsumerState<TenantRejectOrderScreen> createState() =>
      _TenantRejectOrderScreenState();
}

class _TenantRejectOrderScreenState
    extends ConsumerState<TenantRejectOrderScreen> {
  final _otherReasonController = TextEditingController();
  RejectReasonOption? _selectedOption;

  /// The last board entry that matched [TenantRejectOrderScreen.orderId].
  ///
  /// Confirming optimistically REMOVES the order from the board (a cancelled
  /// order is not shown), so a purely live lookup would flip this screen to
  /// its not-found state underneath the success modal. Holding the last
  /// resolved snapshot keeps the confirmed order on screen until the caller
  /// navigates away.
  TenantOrder? _lastResolved;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialReason;
    if (initial == null) return;
    for (final option in RejectReasonOption.values) {
      if (option.title == initial) {
        _selectedOption = option;
        return;
      }
    }
    _otherReasonController.text = initial;
  }

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  /// The free-text reason wins over the selected preset, mirroring
  /// [RejectReasonSheet]. Null means "no reason given yet" — the CTA stays
  /// disabled, since a cancellation the customer sees should say why.
  String? get _reason {
    final custom = _otherReasonController.text.trim();
    if (custom.isNotEmpty) return custom;
    return _selectedOption?.title;
  }

  TenantOrder? _findOrder(List<TenantOrder>? orders) {
    if (orders == null) return null;
    for (final order in orders) {
      if (order.id == widget.orderId) return order;
    }
    return null;
  }

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(TenantRoutes.order);
    }
  }

  Future<void> _confirm(TenantOrder order) async {
    final reason = _reason;
    if (reason == null || _submitting) return;
    setState(() => _submitting = true);

    try {
      await ref
          .read(tenantOrderBoardProvider.notifier)
          .reject(order.id, reason: reason);
    } on Object catch (error) {
      // Covers both the mapped ApiException from the repository and the
      // StateError the board throws when the target order is not on it — a
      // silent success modal here was the exact bug this replaced.
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage(error))),
      );
      return;
    }

    if (!mounted) return;
    await showSuccessModal(
      context,
      title: rejectedOrderModalTitle,
      message: 'Seluruh pesanan dibatalkan dan pelanggan akan diberi tahu',
      confirmLabel: 'Selesai',
      details: [
        SuccessModalDetail(
          icon: Icons.receipt_long_outlined,
          label: 'Pesanan',
          value: '#${order.id}',
        ),
        SuccessModalDetail(
          icon: Icons.info_outline,
          label: 'Alasan penolakan',
          value: reason,
        ),
      ],
      onConfirm: () => context.goNamed(TenantRoutes.pesananDiproses),
    );
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(tenantOrderBoardProvider);
    final order = _findOrder(board.value) ?? _lastResolved;
    if (order != null) _lastResolved = order;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RejectNavBar(title: 'Tolak Pesanan', onBack: _onBack),
            Expanded(
              child: order == null
                  ? _placeholderFor(board)
                  : _buildReasonForm(order),
            ),
            if (order != null)
              _BottomSummary(
                orderTotal: formatRupiah(order.grandTotal),
                onConfirm: _reason == null || _submitting
                    ? null
                    : () => _confirm(order),
              ),
          ],
        ),
      ),
    );
  }

  /// What to show when [TenantRejectOrderScreen.orderId] resolves to nothing:
  /// the board's own failure, its loading state, or — once the board HAS
  /// loaded and still has no such order — an explicit not-found. That last
  /// case used to be invisible, because the screen rendered seeded mock items
  /// regardless of whether the order existed.
  Widget _placeholderFor(AsyncValue<List<TenantOrder>> board) {
    if (board.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            errorMessage(board.error!),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.neutral500,
              fontSize: 14,
              height: 1.2,
            ),
          ),
        ),
      );
    }
    if (board.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          orderNotFoundMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.neutral500,
            fontSize: 14,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildReasonForm(TenantOrder order) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _OrderInfoRow(
          orderId: order.id,
          receiptNumber: order.receiptNumber,
          dateTime: _formatOrderDateTime(order.createdAt),
        ),
        const SizedBox(height: 16),
        const _WholeOrderWarning(),
        const SizedBox(height: 16),
        const Text(
          'Alasan Penolakan',
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
            selected: _selectedOption == option,
            onTap: () => setState(() => _selectedOption = option),
          ),
          const SizedBox(height: 12),
        ],
        RejectOtherReasonField(
          controller: _otherReasonController,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

/// Heading of the rejection-confirmed modal.
const String rejectedOrderModalTitle = 'Pesanan ditolak';

/// Shown when the requested order id is not on the loaded board.
const String orderNotFoundMessage = 'Pesanan tidak ditemukan di daftar order.';

/// Banner heading: this action cancels the entire order, not selected items.
const String wholeOrderRejectionTitle = 'Seluruh pesanan akan ditolak';

/// Banner body spelling out the consequence of confirming.
const String wholeOrderRejectionBody =
    'Penolakan berlaku untuk semua item. Pesanan dibatalkan dan pelanggan '
    'akan diberi tahu.';

/// Label of the bottom CTA. Distinct from the old "Konfirmasi Pesanan", which
/// read as confirming (i.e. accepting) the order.
const String rejectOrderConfirmLabel = 'Konfirmasi Penolakan';

/// White top bar: back chevron + centered dark title.
class _RejectNavBar extends StatelessWidget {
  const _RejectNavBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.chevron_left,
                color: AppColors.neutral900,
                size: 28,
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.neutral900,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// The order identity row: a receipt icon tile + id/status + receipt/datetime.
class _OrderInfoRow extends StatelessWidget {
  const _OrderInfoRow({
    required this.orderId,
    required this.receiptNumber,
    required this.dateTime,
  });

  final String orderId;
  final String receiptNumber;
  final String dateTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.successTint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            // TODO(open-question): Material glyph until the cache icon set is a
            // dependency (mirrors OrderDetail / SuccessModal).
            Icons.receipt_long_outlined,
            size: 22,
            color: AppColors.successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#$orderId',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.neutral900,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Baru',
                    style: TextStyle(
                      color: AppColors.orderBadgeRed,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      // TODO(open-question): the live order shape carries no
                      // table name, so the receipt number fills this slot —
                      // same repurposing as TenantOrder.toIncomingOrderData.
                      receiptNumber,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.neutral500,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      dateTime,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.neutral500,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The banner spelling out that this cancels the ENTIRE order.
///
/// Replaces the old green "Anda dapat menolak sebagian item" /
/// "Pelanggan tetap akan menerima item yang tersedia" pair, which promised
/// partial fulfillment the API cannot perform.
class _WholeOrderWarning extends StatelessWidget {
  const _WholeOrderWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dangerTint,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, size: 24, color: AppColors.dangerRed),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  wholeOrderRejectionTitle,
                  style: TextStyle(
                    color: AppColors.neutral900,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  wholeOrderRejectionBody,
                  style: TextStyle(
                    color: AppColors.neutral500,
                    fontSize: 12,
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

/// The pinned bottom summary + confirm CTA. [onConfirm] is null until a reason
/// has been given, which disables the button.
class _BottomSummary extends StatelessWidget {
  const _BottomSummary({required this.orderTotal, required this.onConfirm});

  final String orderTotal;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Container(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.dangerTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 18,
                        color: AppColors.dangerRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Ringkasan Pesanan',
                                  style: TextStyle(
                                    color: AppColors.neutral900,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Total dibatalkan',
                                style: TextStyle(
                                  color: AppColors.neutral500,
                                  fontSize: 12,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Seluruh item ditolak',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.neutral500,
                                    fontSize: 12,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                orderTotal,
                                style: const TextStyle(
                                  color: AppColors.dangerRed,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: rejectOrderConfirmLabel,
                  onPressed: onConfirm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

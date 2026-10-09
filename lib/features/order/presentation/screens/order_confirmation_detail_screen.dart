import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/order_card.dart';
import 'package:dtw_app/features/order/data/models/order_confirmation.dart';
import 'package:dtw_app/features/order/data/models/order_models.dart';
import 'package:dtw_app/features/order/presentation/providers/order_confirmation_provider.dart';
import 'package:dtw_app/features/order/presentation/widgets/detail_screen_parts.dart';
import 'package:dtw_app/features/order/presentation/widgets/order_detail_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The "Detail Pesanan" screen for a "Perlu Konfirmasi" task (`menu-order-baru`
/// detail, node `2286:13760`): which items the kitchen could not make, and the
/// two decisions the customer can take — "Lanjutkan Pesanan" (PROCEED) or
/// "Batalkan Pesanan" (CANCEL).
///
/// Not shown yet: the Total Awal / Refund / Total Setelah Refund block of the
/// design — `GET /v1/busboy/order-confirmations` items carry no prices.
class OrderConfirmationDetailScreen extends ConsumerStatefulWidget {
  const OrderConfirmationDetailScreen({required this.confirmationId, super.key});

  final String confirmationId;

  @override
  ConsumerState<OrderConfirmationDetailScreen> createState() =>
      _OrderConfirmationDetailScreenState();
}

class _OrderConfirmationDetailScreenState
    extends ConsumerState<OrderConfirmationDetailScreen> {
  /// Last confirmation seen. Deciding removes the task from the open list, so a
  /// purely live lookup would flip this screen to "not found" under the
  /// feedback.
  OrderConfirmation? _last;
  bool _submitting = false;

  Future<void> _decide(
    OrderConfirmation confirmation,
    ConfirmationDecision decision,
  ) async {
    if (_submitting) return;
    if (decision == ConfirmationDecision.cancel &&
        !await _confirmCancel(context)) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(orderConfirmationBoardProvider.notifier)
          .decide(confirmation, decision);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage(error))));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          decision == ConfirmationDecision.proceed
              ? 'Pesanan dilanjutkan'
              : 'Pesanan dibatalkan',
        ),
      ),
    );
    context.goNamed(AppRoutes.order);
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(confirmationByIdProvider(widget.confirmationId));
    final confirmation = live ?? _last;
    if (live != null) _last = live;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DetailNavBar(
            title: 'Detail Pesanan',
            fallbackRoute: AppRoutes.order,
          ),
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -8, 0),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              clipBehavior: Clip.antiAlias,
              child: confirmation == null
                  ? const _NotFound()
                  : _body(confirmation),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(OrderConfirmation confirmation) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        OrderDetailCard(detail: _headerDetail(confirmation)),
        const SizedBox(height: 16),
        _SummaryCard(confirmation: confirmation),
        const SizedBox(height: 16),
        DetailCard(
          child: Column(
            children: [
              _DecisionCard(
                title: 'Lanjutkan Pesanan',
                message: 'Item yang tidak tersedia akan dibatalkan dan dana '
                    'direfund sebagian.',
                icon: Icons.check_circle,
                color: AppColors.successGreen,
                background: AppColors.successTint,
                onTap: _submitting
                    ? null
                    : () => _decide(confirmation, ConfirmationDecision.proceed),
              ),
              const SizedBox(height: 12),
              _DecisionCard(
                title: 'Batalkan Pesanan',
                message: 'Semua item akan dibatalkan dan dana direfund penuh.',
                icon: Icons.cancel,
                color: AppColors.dangerRed,
                background: AppColors.dangerTint,
                onTap: _submitting
                    ? null
                    : () => _decide(confirmation, ConfirmationDecision.cancel),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Adapts the confirmation to the shared header card, which only reads the
  /// id/time/tenant/table/customer fields.
  OrderDetail _headerDetail(OrderConfirmation c) {
    final hh = c.createdAt.hour.toString().padLeft(2, '0');
    final mm = c.createdAt.minute.toString().padLeft(2, '0');
    return OrderDetail(
      orderId: c.orderId,
      displayNumber: c.receiptNumber ?? '-',
      time: '$hh:$mm WIB',
      tenantName: c.brandName ?? '-',
      tableName: c.tableNumber,
      location: '',
      customerName: c.customerName ?? '-',
      itemCount: c.items.length,
      items: const [],
      total: '',
      note: '',
      status: OrderStatus.baru,
    );
  }
}

/// CANCEL refunds the whole order, so it gets one explicit confirmation.
Future<bool> _confirmCancel(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Batalkan pesanan?'),
      content: const Text(
        'Semua item akan dibatalkan dan dana direfund penuh. Ini tidak bisa '
        'diurungkan.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Kembali'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Ya, Batalkan',
            style: TextStyle(color: AppColors.dangerRed),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Konfirmasi tidak ditemukan atau sudah diselesaikan.',
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
}

/// The red "N ITEM TIDAK TERSEDIA" banner + "Ringkasan Pesanan" list. A line
/// the kitchen rejected only in part is split into its accepted and rejected
/// units; the rejected units are red, with the reason underneath.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.confirmation});

  final OrderConfirmation confirmation;

  @override
  Widget build(BuildContext context) {
    final rejected = confirmation.rejectedCount;
    return DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_rounded,
                size: 32,
                color: AppColors.dangerRed,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$rejected ITEM TIDAK TERSEDIA',
                      style: const TextStyle(
                        color: AppColors.dangerRed,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const Text(
                      'Customer Perlu Konfirmasi',
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
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ringkasan Pesanan',
                  style: TextStyle(
                    color: AppColors.neutral900,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              Text(
                '${confirmation.items.length} Item',
                style: const TextStyle(
                  color: AppColors.neutral500,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in confirmation.items) ..._rowsFor(item),
        ],
      ),
    );
  }

  List<Widget> _rowsFor(ConfirmationItem item) {
    final accepted = item.quantity - item.rejectedQuantity;
    return [
      if (accepted > 0)
        _ItemRow(qty: accepted, name: item.productName, rejected: false),
      if (item.isRejected)
        _ItemRow(
          qty: item.rejectedQuantity,
          name: item.productName,
          rejected: true,
          reason: item.rejectionReason,
        ),
    ];
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.qty,
    required this.name,
    required this.rejected,
    this.reason,
  });

  final int qty;
  final String name;
  final bool rejected;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final color = rejected ? AppColors.dangerRed : AppColors.neutral900;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${qty}x',
                  style: TextStyle(color: color, fontSize: 14, height: 1.2),
                ),
              ),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(color: color, fontSize: 14, height: 1.2),
                ),
              ),
            ],
          ),
          if (rejected && reason != null && reason!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 2),
              child: Text(
                reason!,
                style: const TextStyle(
                  color: AppColors.neutral500,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One of the two big decision buttons ("Lanjutkan" green, "Batalkan" red).
class _DecisionCard extends StatelessWidget {
  const _DecisionCard({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    return Material(
      color: background,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 20, color: color),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: AppColors.neutral900,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_right, size: 24, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/utils/currency.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_order_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/reject_confirmed_modal.dart';
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

/// The `pesanan-ditolak` / `konfirmasi-pesanan` screen: the tenant marks
/// which items of a PENDING order are unavailable and confirms.
///
/// **Per-item, backed by `POST /v1/orders/{id}/process`.** Toggling an item
/// off marks it for rejection; confirming sends the rejected items' ids.
/// The backend derives the outcome: none rejected → every item accepted,
/// order → PREPARING; some → the rest accepted, order → PREPARING; all →
/// order → CANCELLED. There is no reason field in that API, so this screen
/// captures none (a prior all-or-nothing version required a cancellation
/// reason for a whole-order-only API; that constraint is gone).
///
/// Every value shown is read off the real [tenantOrderBoardProvider] entry for
/// [orderId] — there is no seeded order data here.
class TenantRejectOrderScreen extends ConsumerStatefulWidget {
  const TenantRejectOrderScreen({
    required this.orderId,
    this.seedFirstItemRejected = false,
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

  /// Seeds the first item as already rejected — only the `konfirmasi-pesanan`
  /// Figma-frame deep link uses this, to preview the some-items-rejected
  /// state for that prototype frame (see `tenant_router.dart`).
  final bool seedFirstItemRejected;

  @override
  ConsumerState<TenantRejectOrderScreen> createState() =>
      _TenantRejectOrderScreenState();
}

class _TenantRejectOrderScreenState
    extends ConsumerState<TenantRejectOrderScreen> {
  /// The last board entry that matched [TenantRejectOrderScreen.orderId].
  ///
  /// Confirming optimistically REMOVES a fully-rejected order from the board
  /// (see `TenantOrderBoard._process`), so a purely live lookup would flip
  /// this screen to its not-found state underneath the success modal.
  /// Holding the last resolved snapshot keeps the confirmed order on screen
  /// until the caller navigates away.
  TenantOrder? _lastResolved;
  bool _submitting = false;

  /// Local, per-item availability state. Seeded once from [_lastResolved]'s
  /// items (see [build]) and then only ever mutated by
  /// [_onAvailabilityChanged] — a live board re-fetch must never clobber a
  /// toggle the tenant already made.
  List<OrderLineItem>? _items;

  List<OrderLineItem> _seedItems(TenantOrder order) {
    final items = order.items;
    if (!widget.seedFirstItemRejected || items.isEmpty) return items;
    return [items.first.copyWith(available: false), ...items.skip(1)];
  }

  void _onAvailabilityChanged(int index, bool available) {
    setState(() {
      final items = List<OrderLineItem>.of(_items!);
      items[index] = items[index].copyWith(available: available);
      _items = items;
    });
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
    if (_submitting) return;
    final items = _items ?? const <OrderLineItem>[];
    final rejectedItemIds = [
      for (final item in items)
        if (!item.available) item.id,
    ];
    setState(() => _submitting = true);

    try {
      await ref
          .read(tenantOrderBoardProvider.notifier)
          .reject(order.id, rejectedItemIds: rejectedItemIds);
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
    final acceptedCount = items.length - rejectedItemIds.length;
    final acceptedTotal = formatRupiah(
      items
          .where((item) => item.available)
          .fold<int>(0, (sum, item) => sum + item.subtotal),
    );
    await showRejectConfirmedModal(
      context,
      acceptedCount: acceptedCount,
      rejectedCount: rejectedItemIds.length,
      acceptedTotal: acceptedTotal,
      onConfirm: () => context.goNamed(TenantRoutes.pesananDiproses),
    );
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(tenantOrderBoardProvider);
    final order = _findOrder(board.value) ?? _lastResolved;
    if (order != null) {
      _lastResolved = order;
      _items ??= List.of(_seedItems(order));
    }
    final items = _items;
    final rejectedCount =
        items == null ? 0 : items.where((item) => !item.available).length;
    final acceptedCount = items == null ? 0 : items.length - rejectedCount;
    final acceptedTotal = formatRupiah(
      items == null
          ? 0
          : items
              .where((item) => item.available)
              .fold<int>(0, (sum, item) => sum + item.subtotal),
    );

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
                  : _buildRejectForm(order, items!),
            ),
            if (order != null)
              _BottomSummary(
                availableCount: acceptedCount,
                totalItems: items?.length ?? 0,
                rejectedCount: rejectedCount,
                acceptedTotal: acceptedTotal,
                onConfirm: rejectedCount == 0 || _submitting
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

  Widget _buildRejectForm(TenantOrder order, List<OrderLineItem> items) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _OrderInfoRow(
          orderId: order.id,
          receiptNumber: order.receiptNumber,
          dateTime: _formatOrderDateTime(order.createdAt),
        ),
        const SizedBox(height: 16),
        const _InfoBanner(),
        const SizedBox(height: 16),
        const Text(
          'Daftar Item',
          style: TextStyle(
            color: AppColors.neutral900,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          OrderItemAvailabilityRow(
            item: items[i],
            onAvailabilityChanged: (available) =>
                _onAvailabilityChanged(i, available),
          ),
        ],
      ],
    );
  }
}

/// Shown when the requested order id is not on the loaded board.
const String orderNotFoundMessage = 'Pesanan tidak ditemukan di daftar order.';

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

/// The light-green info banner explaining partial rejection.
class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.successTint,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, size: 24, color: AppColors.successGreen),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Anda dapat menolak sebagian item',
                  style: TextStyle(
                    color: AppColors.neutral900,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pelanggan tetap akan menerima item yang tersedia',
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

/// The pinned bottom summary + "Konfirmasi Pesanan" CTA. [onConfirm] is null
/// until at least one item is rejected — this screen exists to reject items;
/// accepting everything is the card's "Terima" button instead.
class _BottomSummary extends StatelessWidget {
  const _BottomSummary({
    required this.availableCount,
    required this.totalItems,
    required this.rejectedCount,
    required this.acceptedTotal,
    required this.onConfirm,
  });

  final int availableCount;
  final int totalItems;
  final int rejectedCount;
  final String acceptedTotal;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final hasRejected = rejectedCount > 0;
    final availabilityText = hasRejected
        ? '$availableCount dari $totalItems item tersedia'
        : '$availableCount item tersedia';

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
                if (hasRejected) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.info,
                        size: 20,
                        color: AppColors.dangerRed,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$rejectedCount item ditolak oleh tenant',
                          style: const TextStyle(
                            color: AppColors.neutral900,
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.neutral100,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.successTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 18,
                        color: AppColors.successGreen,
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
                                'Total diterima',
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
                              Expanded(
                                child: Text(
                                  availabilityText,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.neutral500,
                                    fontSize: 12,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                acceptedTotal,
                                style: const TextStyle(
                                  color: AppColors.successGreen,
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
                  label: 'Konfirmasi Pesanan',
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

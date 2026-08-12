import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/utils/currency.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_order_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/reject_confirmed_modal.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/reject_reason_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

export 'package:dtw_app/core/utils/currency.dart' show formatRupiah;

/// A per-item line on the reject screen: the display item plus its numeric
/// price (so accepted totals can be recomputed) and, when rejected, the reason.
class _RejectLine {
  _RejectLine({required this.name, required this.priceValue});

  final String name;
  final int priceValue;
  final int qty = 1;
  bool available = true;
  String? reason;

  OrderLineItem get item => OrderLineItem(
        name: name,
        price: formatRupiah(priceValue),
        qty: qty,
        available: available,
      );
}

/// The `pesanan-ditolak` / `konfirmasi-pesanan` screen: the tenant marks which
/// items of an incoming order are unavailable (per-item, L6). Toggling an item
/// off opens the `alasan-penolakan` reason modal; once a reason is captured the
/// row switches to its rejected style and a "N item ditolak" banner appears
/// (the `konfirmasi-pesanan` state). "Konfirmasi Pesanan" confirms the
/// (partial) rejection, raises the `berhasil-ditambahkan-2` modal and lands on
/// the Diproses sub-tab.
///
/// Both routes render this one screen: `pesanan-ditolak` starts all-available,
/// `konfirmasi-pesanan` deep-links straight to the confirmed state by seeding
/// [initialRejectedName] / [initialRejectedReason].
class TenantRejectOrderScreen extends ConsumerStatefulWidget {
  const TenantRejectOrderScreen({
    this.orderId = '92842',
    this.tableName = 'Meja A-12',
    this.dateTime = '10 Mei 2024 10:36 WIB',
    this.initialRejectedName,
    this.initialRejectedReason = 'Stok Habis',
    super.key,
  });

  /// Order number without the leading `#`.
  final String orderId;

  /// Destination table label.
  final String tableName;

  /// Quoted date + time shown in the order info row.
  final String dateTime;

  /// When set, that item starts rejected (the `konfirmasi-pesanan` state).
  final String? initialRejectedName;

  /// Reason seeded for [initialRejectedName].
  final String initialRejectedReason;

  @override
  ConsumerState<TenantRejectOrderScreen> createState() =>
      _TenantRejectOrderScreenState();
}

class _TenantRejectOrderScreenState
    extends ConsumerState<TenantRejectOrderScreen> {
  // TODO(open-question): the order data source is unresolved; these lines are
  // the harvested mock for #92842 (Meja A-12). When the real source lands,
  // parameterise the screen by order id off the repository.
  late final List<_RejectLine> _lines = [
    _RejectLine(name: 'Paket Super Besar', priceValue: 35000),
    _RejectLine(name: 'Es Lemon Tea', priceValue: 5000),
  ];

  @override
  void initState() {
    super.initState();
    final name = widget.initialRejectedName;
    if (name != null) {
      for (final line in _lines) {
        if (line.name == name) {
          line
            ..available = false
            ..reason = widget.initialRejectedReason;
        }
      }
    }
  }

  int get _availableCount => _lines.where((l) => l.available).length;
  int get _rejectedCount => _lines.where((l) => !l.available).length;
  int get _acceptedTotal =>
      _lines.where((l) => l.available).fold(0, (s, l) => s + l.priceValue);

  Future<void> _onAvailabilityChanged(_RejectLine line, bool available) async {
    if (available) {
      setState(() {
        line
          ..available = true
          ..reason = null;
      });
      return;
    }
    // Rejecting an item requires a reason first.
    final reason = await showRejectReasonSheet(context, item: line.item);
    if (!mounted || reason == null) return;
    setState(() {
      line
        ..available = false
        ..reason = reason;
    });
  }

  Future<void> _confirm() async {
    final rejectedNames =
        _lines.where((l) => !l.available).map((l) => l.name).toList();
    final reason = _lines
        .firstWhere((l) => !l.available, orElse: () => _lines.first)
        .reason;

    ref.read(tenantOrderBoardProvider.notifier).reject(
          widget.orderId,
          reason: reason ?? '',
          rejectedItemNames: rejectedNames,
        );

    await showRejectConfirmedModal(
      context,
      acceptedCount: _availableCount,
      rejectedCount: _rejectedCount,
      acceptedTotal: formatRupiah(_acceptedTotal),
      onConfirm: () => context.goNamed(TenantRoutes.pesananDiproses),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RejectNavBar(
              title: 'Tolak Pesanan',
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.goNamed(TenantRoutes.order);
                }
              },
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _OrderInfoRow(
                    orderId: widget.orderId,
                    tableName: widget.tableName,
                    dateTime: widget.dateTime,
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
                  for (var i = 0; i < _lines.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    OrderItemAvailabilityRow(
                      item: _lines[i].item,
                      reason: _lines[i].reason,
                      onAvailabilityChanged: (v) =>
                          _onAvailabilityChanged(_lines[i], v),
                    ),
                  ],
                ],
              ),
            ),
            _BottomSummary(
              availableCount: _availableCount,
              totalItems: _lines.length,
              rejectedCount: _rejectedCount,
              acceptedTotal: formatRupiah(_acceptedTotal),
              onConfirm: _confirm,
            ),
          ],
        ),
      ),
    );
  }
}

/// White top bar: status row, back chevron + centered dark title.
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

/// The order identity row: a receipt icon tile + id/status + table/datetime.
class _OrderInfoRow extends StatelessWidget {
  const _OrderInfoRow({
    required this.orderId,
    required this.tableName,
    required this.dateTime,
  });

  final String orderId;
  final String tableName;
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
                      tableName,
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

/// The pinned bottom summary + "Konfirmasi Pesanan" CTA.
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
  final VoidCallback onConfirm;

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

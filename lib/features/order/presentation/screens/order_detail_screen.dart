import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/order_card.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/core/widgets/success_modal.dart';
import 'package:dtw_app/features/order/data/models/order_models.dart';
import 'package:dtw_app/features/order/presentation/providers/order_provider.dart';
import 'package:dtw_app/features/order/presentation/widgets/order_detail_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The `menu-order-baru-2` frame: the "Detail Pesanan" screen.
///
/// Interpretation (see report): this is a dedicated full order-detail screen —
/// its own "Detail Pesanan" nav bar and a bottom "Ambil Pesanan" CTA — NOT an
/// expanded list-card state and NOT a populated list. It is reached from a
/// Baru card's "Detail" affordance. The CTA takes the order (mock Baru → Antar)
/// and raises the shared success modal (`berhasil-ditambahkan`); its
/// `onConfirm` returns to the Order home on the Antar sub-tab.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({this.orderId = '92842', super.key});

  /// Order id to load. Defaults to the single harvested mock.
  final String orderId;

  Future<void> _take(BuildContext context, WidgetRef ref) async {
    // TODO(open-question): the detail screen isn't parameterised by list index
    // yet (only one mock order exists); take the first Baru order.
    ref.read(orderBoardNotifierProvider.notifier).takeBaru(0);
    await showSuccessModal(
      context,
      // Uses the SuccessModal frame defaults (Tugas Berhasil Diambil! …).
      onConfirm: () {
        ref.read(orderTabProvider.notifier).selectStatus(OrderStatus.antar);
        context.goNamed(AppRoutes.order);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DetailNavBar(title: 'Detail Pesanan'),
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -8, 0),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  OrderDetailCard(
                    detail: detail,
                    onCall: () {
                      // TODO(open-question): calling the customer is out of
                      // scope / no telephony flow specified.
                    },
                  ),
                  const SizedBox(height: 16),
                  _SummaryCard(detail: detail),
                  const SizedBox(height: 16),
                  _NoteCard(note: detail.note),
                ],
              ),
            ),
          ),
          _BottomAction(onPressed: () => _take(context, ref)),
        ],
      ),
    );
  }
}

/// Green nav bar: white status bar over a back arrow + centered title.
class _DetailNavBar extends StatelessWidget {
  const _DetailNavBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.headerGreenTop, AppColors.headerGreenBottom],
        ),
      ),
      child: Column(
        children: [
          const _WhiteStatusBar(),
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.goNamed(AppRoutes.order);
                      }
                    },
                    icon: const Icon(
                      Icons.chevron_left,
                      color: AppColors.white,
                      size: 28,
                    ),
                  ),
                ),
                Text(
                  title,
                  // TODO(open-question): Open Sans Bold in the cache; not
                  // bundled.
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// "Ringkasan Pesanan" card: title + item count, line items, hairline, total.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.detail});

  final OrderDetail detail;

  static const TextStyle _titleStyle = TextStyle(
    color: AppColors.neutral900,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const TextStyle _mutedStyle = TextStyle(
    color: AppColors.neutral500,
    fontSize: 14,
    height: 1.2,
  );
  static const TextStyle _bodyStyle = TextStyle(
    color: AppColors.neutral900,
    fontSize: 14,
    height: 1.3,
  );
  static const TextStyle _totalStyle = TextStyle(
    color: AppColors.neutral900,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Ringkasan Pesanan', style: _titleStyle),
              ),
              Text('${detail.itemCount} Item', style: _mutedStyle),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < detail.items.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _lineItem(detail.items[i]),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.neutral100,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Total Pesanan', style: _totalStyle),
              ),
              Text(
                detail.total,
                style: const TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lineItem(OrderLineItem item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text('${item.qty}x', style: _bodyStyle),
              ),
              const SizedBox(width: 8),
              Flexible(child: Text(item.name, style: _bodyStyle)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(item.price, style: _bodyStyle),
      ],
    );
  }
}

/// "Catatan dari Pelanggan" card.
class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Catatan dari Pelanggan',
            style: TextStyle(
              color: AppColors.neutral900,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            note,
            style: const TextStyle(
              color: AppColors.neutral500,
              fontSize: 14,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared white rounded card used by the summary / note sections.
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
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

/// The pinned bottom "Ambil Pesanan" CTA bar.
class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: PrimaryButton(label: 'Ambil Pesanan', onPressed: onPressed),
        ),
      ),
    );
  }
}

/// White-on-green status bar (`9:41`). Mirrors the other headers.
// TODO(open-question): pixel-exact SVG glyphs are approximated with Material
// icons until flutter_svg is available.
class _WhiteStatusBar extends StatelessWidget {
  const _WhiteStatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 44,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '9:41',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
            Row(
              children: [
                Icon(Icons.signal_cellular_alt, size: 17, color: Colors.white),
                SizedBox(width: 6),
                Icon(Icons.wifi, size: 17, color: Colors.white),
                SizedBox(width: 6),
                Icon(Icons.battery_full, size: 22, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

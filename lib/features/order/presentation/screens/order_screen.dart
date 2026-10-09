import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/error_view.dart';
import 'package:dtw_app/core/widgets/order_card.dart';
import 'package:dtw_app/core/widgets/segmented_tab_bar.dart';
import 'package:dtw_app/core/widgets/success_modal.dart';
import 'package:dtw_app/features/order/data/models/order_confirmation.dart';
import 'package:dtw_app/features/order/data/models/order_models.dart';
import 'package:dtw_app/features/order/presentation/providers/order_confirmation_provider.dart';
import 'package:dtw_app/features/order/presentation/providers/order_provider.dart';
import 'package:dtw_app/features/order/presentation/widgets/order_confirmation_card.dart';
import 'package:dtw_app/features/order/presentation/widgets/order_empty_state.dart';
import 'package:dtw_app/features/order/presentation/widgets/order_home_header.dart';
import 'package:dtw_app/features/order/presentation/widgets/order_success_details.dart';
import 'package:dtw_app/features/order/presentation/widgets/order_tab_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:obra_icons/obra_icons.dart';

/// The `menu-order-baru` / `-antar` / `-selesai` frames: the Order-tab home.
///
/// One screen hosts all three sub-tabs (Ambil / Antar / Selesai); the shared
/// `SegmentedTabBar` switches the list in place. Backed by the real,
/// zone-scoped [orderBoardProvider] (`GET /v1/busboy/deliveries`).
/// The `Sampai dimeja` action on an Antar card calls the real `complete`
/// endpoint, then raises the shared success modal (`berhasil-ditambahkan-2`)
/// whose `onConfirm` switches to the Selesai sub-tab. Hosted inside the app
/// shell, so the bottom nav is provided by `AppShell`.
class OrderScreen extends ConsumerWidget {
  const OrderScreen({super.key});

  static const List<OrderStatus> _statuses = [
    OrderStatus.baru,
    OrderStatus.antar,
    OrderStatus.selesai,
  ];

  void _openDetail(BuildContext context, String orderId) {
    context.goNamed(
      AppRoutes.orderDetail,
      pathParameters: {'orderId': orderId},
    );
  }

  void _openConfirmation(BuildContext context, String confirmationId) {
    context.goNamed(
      AppRoutes.orderConfirmationDetail,
      pathParameters: {'confirmationId': confirmationId},
    );
  }

  void _openSelesaiDetail(BuildContext context, String orderId) {
    context.goNamed(
      AppRoutes.orderSelesaiDetail,
      pathParameters: {'orderId': orderId},
    );
  }

  Future<void> _deliver(
    BuildContext context,
    WidgetRef ref,
    OrderCardData data,
  ) async {
    try {
      await ref.read(orderBoardProvider.notifier).deliver(data.orderId);
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage(error))));
      return;
    }

    if (!context.mounted) return;
    await showSuccessModal(
      context,
      title: DeliveredOrderCopy.title,
      message: DeliveredOrderCopy.message,
      confirmLabel: DeliveredOrderCopy.confirmLabel,
      details: deliveredOrderDetails(
        tableName: data.tableName,
        customerName: data.customerName,
      ),
      onConfirm: () =>
          ref.read(orderTabProvider.notifier).selectStatus(OrderStatus.selesai),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(orderHeaderStatsProvider);
    final boardAsync = ref.watch(orderBoardProvider);
    final selected = ref.watch(orderTabProvider);
    final status = _statuses[selected];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderHomeHeader(
            stats: stats,
            name: ref.watch(sessionNameProvider),
          ),
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -8, 0),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              clipBehavior: Clip.antiAlias,
              child: boardAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorView(
                  message: errorMessage(error),
                  onRetry: () => ref.invalidate(orderBoardProvider),
                ),
                data: (deliveries) => _buildBody(
                  context,
                  ref,
                  orderBoardFrom(deliveries),
                  status,
                  selected,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    OrderBoard board,
    OrderStatus status,
    int selected,
  ) {
    final orders = board.listFor(status);
    // "Perlu Konfirmasi" tasks live on the Ambil (baru) tab only.
    final confirmations = status == OrderStatus.baru
        ? ref.watch(openConfirmationsProvider)
        : const <OrderConfirmation>[];
    final ambilCount =
        board.baru.length + ref.watch(openConfirmationsProvider).length;

    return Column(
      children: [
        SegmentedTabBar(
          selectedIndex: selected,
          onChanged: (i) => ref.read(orderTabProvider.notifier).select(i),
          items: [
            SegmentedTabItem(
              label: 'Ambil',
              icon: Icons.room_service_outlined,
              badge: ambilCount == 0
                  ? null
                  : OrderTabBadge(
                      count: ambilCount,
                      color: AppColors.orderBadgeRed,
                    ),
            ),
            SegmentedTabItem(
              // TODO(open-question): no obra "hand-platter" glyph;
              // approximated with a Material serving icon.
              label: 'Antar',
              icon: Icons.restaurant_outlined,
              badge: board.antar.isEmpty
                  ? null
                  : OrderTabBadge(
                      count: board.antar.length,
                      color: AppColors.orderBadgeAmber,
                    ),
            ),
            const SegmentedTabItem(label: 'Selesai', icon: ObraIcons.thumbs_up),
          ],
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(orderConfirmationBoardProvider);
              await ref.refresh(orderBoardProvider.future);
            },
            child: orders.isEmpty && confirmations.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [OrderEmptyState(status: status)],
                  )
                : _OrderList(
                    confirmations: confirmations,
                    onConfirmationDetail: (id) =>
                        _openConfirmation(context, id),
                    orders: orders,
                    onDetail: (orderId) => _openDetail(context, orderId),
                    onSelesaiDetail: (orderId) =>
                        _openSelesaiDetail(context, orderId),
                    onDeliver: (data) => _deliver(context, ref, data),
                  ),
          ),
        ),
      ],
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.confirmations,
    required this.onConfirmationDetail,
    required this.orders,
    required this.onDetail,
    required this.onSelesaiDetail,
    required this.onDeliver,
  });

  final List<OrderConfirmation> confirmations;
  final ValueChanged<String> onConfirmationDetail;
  final List<OrderCardData> orders;
  final ValueChanged<String> onDetail;
  final ValueChanged<String> onSelesaiDetail;
  final ValueChanged<OrderCardData> onDeliver;

  @override
  Widget build(BuildContext context) {
    // With confirmations present the Ambil tab splits into two titled
    // sections (`menu-order-baru`): "Konfirmasi" then "Siap diantar".
    final sectioned = confirmations.isNotEmpty;
    final children = <Widget>[
      if (sectioned) const _SectionTitle('Konfirmasi'),
      for (final c in confirmations)
        OrderConfirmationCard(
          confirmation: c,
          onTap: () => onConfirmationDetail(c.id),
        ),
      if (sectioned && orders.isNotEmpty) const _SectionTitle('Siap diantar'),
      for (final data in orders) _orderCard(data),
    ];
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: children.length,
      separatorBuilder: (_, i) =>
          SizedBox(height: children[i] is _SectionTitle ? 12 : 16),
      itemBuilder: (context, i) => children[i],
    );
  }

  Widget _orderCard(OrderCardData data) {
    final isSelesai = data.status == OrderStatus.selesai;
    return OrderCard(
      data: data,
      // Selesai cards open the completed-order detail (`detail-selesai`);
      // Baru/Antar open the pickup detail (`menu-order-baru-2`).
      onTap: isSelesai
          ? () => onSelesaiDetail(data.orderId)
          : () => onDetail(data.orderId),
      onDetailTap: () => onDetail(data.orderId),
      onPrimaryAction:
          data.status == OrderStatus.antar ? () => onDeliver(data) : null,
    );
  }
}

/// A bold section heading on the Ambil tab ("Konfirmasi", "Siap diantar").
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.neutral900,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }
}

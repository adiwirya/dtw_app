import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/segmented_tab_bar.dart';
import 'package:dtw_app/features/order/presentation/widgets/order_tab_badge.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_order_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/tenant_order_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The tenant Order-tab home (`menu-order-baru` / `menu-diproses` / `selesai`).
///
/// One screen hosts all three sub-tabs (Order Baru / Diproses / Selesai); the
/// shared [SegmentedTabBar] switches the list in place (mirroring the busboy
/// `OrderScreen` pattern). The visible list is filtered from the mock
/// [tenantOrderBoardProvider] by [IncomingOrderStatus]; "Terima" promotes a
/// Baru order to Diproses and "Siap Diambil" promotes a Diproses order to
/// Selesai, both UI-only mock transitions.
///
/// [initialStatus] seeds the active sub-tab so the `/order/diproses`,
/// `/order/pesanan-diproses` and `/order/selesai` routes can reuse this screen.
class TenantOrderScreen extends ConsumerStatefulWidget {
  const TenantOrderScreen({
    this.initialStatus = IncomingOrderStatus.baru,
    super.key,
  });

  /// The sub-tab selected on first render.
  final IncomingOrderStatus initialStatus;

  @override
  ConsumerState<TenantOrderScreen> createState() => _TenantOrderScreenState();
}

class _TenantOrderScreenState extends ConsumerState<TenantOrderScreen> {
  static const List<IncomingOrderStatus> _statuses = [
    IncomingOrderStatus.baru,
    IncomingOrderStatus.diproses,
    IncomingOrderStatus.selesai,
  ];

  late int _selected = _statuses.indexOf(widget.initialStatus);

  int _countFor(List<IncomingOrderData> board, IncomingOrderStatus status) =>
      board.where((order) => order.status == status).length;

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(tenantOrderBoardProvider);
    final status = _statuses[_selected];
    final orders =
        board.where((order) => order.status == status).toList(growable: false);
    final baruCount = _countFor(board, IncomingOrderStatus.baru);
    final diprosesCount = _countFor(board, IncomingOrderStatus.diproses);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TenantOrderHeader(tenantName: 'KFC\nFried Chicken'),
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -12, 0),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SegmentedTabBar(
                      selectedIndex: _selected,
                      onChanged: (i) => setState(() => _selected = i),
                      items: [
                        SegmentedTabItem(
                          label: 'Order Baru',
                          badge: baruCount == 0
                              ? null
                              : OrderTabBadge(
                                  count: baruCount,
                                  color: AppColors.orderBadgeRed,
                                ),
                        ),
                        SegmentedTabItem(
                          label: 'Diproses',
                          badge: diprosesCount == 0
                              ? null
                              : OrderTabBadge(
                                  count: diprosesCount,
                                  color: AppColors.orderBadgeAmber,
                                ),
                        ),
                        const SegmentedTabItem(label: 'Selesai'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: orders.isEmpty
                        ? const _EmptyOrders()
                        : _OrderList(
                            orders: orders,
                            onAccept: (order) => ref
                                .read(tenantOrderBoardProvider.notifier)
                                .accept(order.orderId),
                            onPickupReady: (order) => ref
                                .read(tenantOrderBoardProvider.notifier)
                                .markReady(order.orderId),
                            onReject: (order) =>
                                context.goNamed(TenantRoutes.pesananDitolak),
                            // Tapping a card opens the order view
                            // (menu-order-baru-2).
                            onOpenDetail: (order) =>
                                context.goNamed(TenantRoutes.orderDetail),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.onAccept,
    required this.onPickupReady,
    required this.onReject,
    required this.onOpenDetail,
  });

  final List<IncomingOrderData> orders;
  final ValueChanged<IncomingOrderData> onAccept;
  final ValueChanged<IncomingOrderData> onPickupReady;
  final ValueChanged<IncomingOrderData> onReject;
  final ValueChanged<IncomingOrderData> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final order = orders[i];
        return IncomingOrderCard(
          data: order,
          acceptLabel: order.status == IncomingOrderStatus.baru
              ? 'Terima (29s)'
              : null,
          onTap: () => onOpenDetail(order),
          onAccept: () => onAccept(order),
          onReject: () => onReject(order),
          onPickupReady: () => onPickupReady(order),
        );
      },
    );
  }
}

/// Placeholder shown when a sub-tab has no orders.
class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Belum ada pesanan',
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

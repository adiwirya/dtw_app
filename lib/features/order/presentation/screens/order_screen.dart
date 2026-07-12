import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/order_card.dart';
import 'package:dtw_app/core/widgets/segmented_tab_bar.dart';
import 'package:dtw_app/core/widgets/success_modal.dart';
import 'package:dtw_app/features/order/presentation/providers/order_provider.dart';
import 'package:dtw_app/features/order/presentation/widgets/order_empty_state.dart';
import 'package:dtw_app/features/order/presentation/widgets/order_home_header.dart';
import 'package:dtw_app/features/order/presentation/widgets/order_tab_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:obra_icons/obra_icons.dart';

/// The `menu-order-baru` / `-antar` / `-selesai` frames: the Order-tab home.
///
/// One screen hosts all three sub-tabs (Ambil / Antar / Selesai); the shared
/// `SegmentedTabBar` switches the list in place. Populated and empty states are
/// driven by the mock board provider. The `Sampai dimeja` action on an Antar
/// card raises the shared success modal (`berhasil-ditambahkan-2`) whose
/// `onConfirm` switches to the Selesai sub-tab. Hosted inside the app shell, so
/// the bottom nav is provided by `AppShell`.
class OrderScreen extends ConsumerWidget {
  const OrderScreen({super.key});

  static const List<OrderStatus> _statuses = [
    OrderStatus.baru,
    OrderStatus.antar,
    OrderStatus.selesai,
  ];

  void _openDetail(BuildContext context) {
    context.goNamed(AppRoutes.orderDetail);
  }

  void _openSelesaiDetail(BuildContext context) {
    context.goNamed(AppRoutes.orderSelesaiDetail);
  }

  Future<void> _deliver(BuildContext context, WidgetRef ref, int index) async {
    ref.read(orderBoardNotifierProvider.notifier).deliverAntar(index);
    await showSuccessModal(
      context,
      title: 'Sampai dimeja',
      message: 'Pesanan telah berhasil diantar',
      confirmLabel: 'Lanjutkan',
      details: const [
        SuccessModalDetail(
          icon: Icons.chair_outlined,
          label: 'Ke Meja',
          value: 'Meja A-12  •  Downtown',
          tileColor: AppColors.successTint,
          iconColor: AppColors.successGreen,
        ),
        SuccessModalDetail(
          icon: Icons.person_outline,
          label: 'Pelanggan',
          value: 'Budi Santoso',
          tileColor: AppColors.orderTileCustomerBg,
          iconColor: AppColors.orderTileCustomerIcon,
        ),
        SuccessModalDetail(
          // TODO(open-question): no obra "timer" glyph exported; approximated.
          icon: Icons.timer_outlined,
          label: 'Waktu Sampai',
          value: '10:45 WIB  •  12 Mei 2024',
          tileColor: AppColors.orderTileTenantBg,
          iconColor: AppColors.accentBlue,
        ),
      ],
      onConfirm: () =>
          ref.read(orderTabProvider.notifier).selectStatus(OrderStatus.selesai),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(orderHeaderStatsProvider);
    final board = ref.watch(orderBoardNotifierProvider);
    final selected = ref.watch(orderTabProvider);
    final status = _statuses[selected];
    final orders = board.listFor(status);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderHomeHeader(stats: stats),
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -8, 0),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SegmentedTabBar(
                    selectedIndex: selected,
                    onChanged: (i) =>
                        ref.read(orderTabProvider.notifier).select(i),
                    items: [
                      SegmentedTabItem(
                        label: 'Ambil',
                        icon: Icons.room_service_outlined,
                        badge: board.baru.isEmpty
                            ? null
                            : OrderTabBadge(
                                count: board.baru.length,
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
                      const SegmentedTabItem(
                        label: 'Selesai',
                        icon: ObraIcons.thumbs_up,
                      ),
                    ],
                  ),
                  Expanded(
                    child: orders.isEmpty
                        ? OrderEmptyState(status: status)
                        : _OrderList(
                            orders: orders,
                            onDetail: () => _openDetail(context),
                            onSelesaiDetail: () => _openSelesaiDetail(context),
                            onDeliver: (i) => _deliver(context, ref, i),
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
    required this.onDetail,
    required this.onSelesaiDetail,
    required this.onDeliver,
  });

  final List<OrderCardData> orders;
  final VoidCallback onDetail;
  final VoidCallback onSelesaiDetail;
  final ValueChanged<int> onDeliver;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final data = orders[i];
        final isSelesai = data.status == OrderStatus.selesai;
        return OrderCard(
          data: data,
          // Selesai cards open the completed-order detail (`detail-selesai`);
          // Baru/Antar open the pickup detail (`menu-order-baru-2`).
          onTap: isSelesai ? onSelesaiDetail : onDetail,
          onDetailTap: onDetail,
          onPrimaryAction:
              data.status == OrderStatus.antar ? () => onDeliver(i) : null,
        );
      },
    );
  }
}

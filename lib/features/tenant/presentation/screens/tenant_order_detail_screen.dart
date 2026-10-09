import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/utils/currency.dart';
import 'package:dtw_app/core/widgets/error_view.dart';
import 'package:dtw_app/core/widgets/order_card.dart' show OrderStatus;
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/core/widgets/secondary_button.dart';
import 'package:dtw_app/features/order/data/models/order_models.dart';
import 'package:dtw_app/features/order/presentation/widgets/detail_screen_parts.dart';
import 'package:dtw_app/features/order/presentation/widgets/order_detail_card.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_order_actions.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_order_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart'
    show IncomingOrderStatus;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The `menu-order-baru-2` frame: the tenant's "Detail Pesanan" screen,
/// reached by tapping an order card.
///
/// Same layout as the busboy detail screen (shared parts in
/// `detail_screen_parts.dart`), but the bottom bar follows the Order list:
/// - Baru: "Tolak" + "Terima" (Terima also prints the bon),
/// - Diproses: "Siap Diambil", or "Verifikasi Pickup" for a self-pickup order
///   that is already ready,
/// - Selesai: no actions.
///
/// There is no customer phone number on the tenant side, so the call button is
/// left out; the customer's name shows `-` until the API sends one.
class TenantOrderDetailScreen extends ConsumerWidget {
  const TenantOrderDetailScreen({required this.orderId, super.key});

  /// The tapped order's id (from the `baru-2/:orderId` route param).
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(tenantOrderBoardProvider);
    final tenantName =
        ref.watch(currentTenantBranchProvider).value?.branchName ?? '-';

    TenantOrder? order;
    for (final candidate in boardAsync.value ?? const <TenantOrder>[]) {
      if (candidate.id == orderId) {
        order = candidate;
        break;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DetailNavBar(
            title: 'Detail Pesanan',
            fallbackRoute: TenantRoutes.order,
          ),
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -8, 0),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildBody(ref, boardAsync, order, tenantName),
            ),
          ),
          if (order != null) ?_bottomBar(context, ref, order),
        ],
      ),
    );
  }

  Widget _buildBody(
    WidgetRef ref,
    AsyncValue<List<TenantOrder>> boardAsync,
    TenantOrder? order,
    String tenantName,
  ) {
    if (order != null) {
      final detail = _toDetail(order, tenantName);
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // No `onCall`: the tenant side has no customer phone number.
          OrderDetailCard(detail: detail),
          const SizedBox(height: 16),
          OrderSummaryCard(detail: detail, showItemNotes: true),
        ],
      );
    }
    if (boardAsync.hasError) {
      return ErrorView(
        message: errorMessage(boardAsync.error!),
        onRetry: () => ref.invalidate(tenantOrderBoardProvider),
      );
    }
    if (boardAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Pesanan tidak ditemukan.',
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

  Widget? _bottomBar(BuildContext context, WidgetRef ref, TenantOrder order) {
    switch (incomingOrderStatusFromBackend(
      order.status,
      order.fulfillmentType,
    )) {
      case IncomingOrderStatus.baru:
        return DetailBottomBar(
          child: Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Tolak',
                  color: AppColors.dangerRed,
                  onPressed: () => context.goNamed(
                    TenantRoutes.pesananDitolak,
                    pathParameters: {'orderId': order.id},
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Terima',
                  onPressed: () => _run(
                    context,
                    () => acceptOrderAndPrint(ref, order.id),
                  ),
                ),
              ),
            ],
          ),
        );
      case IncomingOrderStatus.diproses:
        final verify =
            order.fulfillmentType == OrderFulfillmentType.selfPickup &&
            order.status == TenantOrderStatus.ready;
        return DetailBottomBar(
          child: verify
              ? PrimaryButton(
                  label: 'Verifikasi Pickup',
                  onPressed: () => context.goNamed(
                    TenantRoutes.verifikasiPickup,
                    pathParameters: {'orderId': order.id},
                  ),
                )
              : PrimaryButton(
                  label: 'Siap Diambil',
                  onPressed: () => _run(
                    context,
                    () => ref
                        .read(tenantOrderBoardProvider.notifier)
                        .markReady(order.id),
                  ),
                ),
        );
      case IncomingOrderStatus.selesai:
        return null;
    }
  }

  /// Runs a board action, then returns to the Order list (the order has moved
  /// to another tab). A failure stays on this screen with a SnackBar.
  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage(error))));
      return;
    }
    if (!context.mounted) return;
    context.goNamed(TenantRoutes.order);
  }

  /// Adapts a [TenantOrder] to the detail widgets' shared [OrderDetail].
  /// `status` is only meaningful to the busboy side; the shared widgets here
  /// don't read it.
  OrderDetail _toDetail(TenantOrder order, String tenantName) {
    final hh = order.createdAt.hour.toString().padLeft(2, '0');
    final mm = order.createdAt.minute.toString().padLeft(2, '0');
    final customer = order.customerName?.trim();
    return OrderDetail(
      orderId: order.id,
      displayNumber: order.receiptNumber,
      time: '$hh:$mm WIB',
      tenantName: tenantName,
      tableName: order.tableNumber == null ? '-' : 'Meja ${order.tableNumber}',
      location: order.fulfillmentType == OrderFulfillmentType.delivery
          ? 'Delivery'
          : 'Pickup',
      customerName: customer == null || customer.isEmpty ? '-' : customer,
      itemCount: order.items.length,
      items: [
        for (final item in order.items)
          OrderLineItem(
            qty: item.qty,
            name: item.name,
            price: item.price,
            notes: item.notes,
          ),
      ],
      total: formatRupiah(order.grandTotal),
      note: '',
      status: OrderStatus.baru,
    );
  }
}

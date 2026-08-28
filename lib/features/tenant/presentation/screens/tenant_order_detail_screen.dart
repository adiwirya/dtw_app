import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_order_provider.dart';
import 'package:dtw_app/features/tenant/presentation/screens/tenant_order_screen.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The `menu-order-baru-2` frame — the order view reached from tapping an
/// Order card.
///
/// Interpretation (see report): unlike the busboy `menu-order-baru-2`, which
/// is a dedicated "Detail Pesanan" screen, the tenant `menu-order-baru-2`
/// reference is pixel-identical to the tenant Order home (same green header,
/// the Baru/Diproses/Selesai tabs, cards). It is a prototype
/// navigation-target duplicate of `menu-order-baru`, so this screen
/// reproduces it by delegating to [TenantOrderScreen] instead of duplicating
/// its layout. [orderId] — the tapped card's order — is used only to pick
/// the sub-tab that order is actually on, so the destination reflects what
/// was tapped instead of always landing on Baru.
class TenantOrderDetailScreen extends ConsumerWidget {
  const TenantOrderDetailScreen({required this.orderId, super.key});

  /// The tapped order's id (from the `baru-2/:orderId` route param).
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(tenantOrderBoardProvider).valueOrNull;
    TenantOrder? order;
    for (final candidate in board ?? const <TenantOrder>[]) {
      if (candidate.id == orderId) {
        order = candidate;
        break;
      }
    }
    // Falls back to Baru when the board hasn't loaded yet or the order
    // already left the board (e.g. accepted/rejected between the tap and
    // this frame) — never a case worth failing the navigation over.
    final status = order == null
        ? IncomingOrderStatus.baru
        : incomingOrderStatusFromBackend(order.status);

    return TenantOrderScreen(initialStatus: status);
  }
}

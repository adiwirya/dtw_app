import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/widgets/completed_detail_view.dart';
import 'package:dtw_app/features/order/presentation/providers/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The `detail-selesai` frame: the completed-order detail page reached from a
/// Selesai sub-tab order card
/// (`context.goNamed(AppRoutes.orderSelesaiDetail)`).
///
/// Layout is the shared [CompletedDetailView]; only the `Informasi Pesanan`
/// "Tenan" value differs from `detail-riwayat`. Back returns to the Order
/// Selesai sub-tab (pop when poppable, else the parent route).
class OrderSelesaiDetailScreen extends ConsumerWidget {
  const OrderSelesaiDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(completedOrderDetailProvider);
    return CompletedDetailView(
      detail: detail,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.goNamed(AppRoutes.orderSelesai);
        }
      },
    );
  }
}

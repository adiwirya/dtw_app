import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/completed_detail_view.dart';
import 'package:dtw_app/features/order/presentation/providers/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The `detail-selesai` frame: the completed-order detail page reached from a
/// Selesai sub-tab order card (`context.goNamed(AppRoutes.orderSelesaiDetail,
/// pathParameters: {'orderId': ...})`).
///
/// Layout is the shared [CompletedDetailView]; only the `Informasi Pesanan`
/// "Tenan" value differs from `detail-riwayat`. Back returns to the Order
/// Selesai sub-tab (pop when poppable, else the parent route).
class OrderSelesaiDetailScreen extends ConsumerWidget {
  const OrderSelesaiDetailScreen({required this.orderId, super.key});

  /// Delivery id to load (a path parameter — see `app_router.dart`).
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(orderBoardNotifierProvider);
    final detail = ref.watch(completedOrderDetailProvider(orderId));

    void onBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(AppRoutes.orderSelesai);
      }
    }

    if (detail != null) {
      return CompletedDetailView(detail: detail, onBack: onBack);
    }
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: boardAsync.isLoading
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    boardAsync.hasError
                        ? errorMessage(boardAsync.error!)
                        : 'Pesanan tidak ditemukan di daftar order.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.neutral500,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

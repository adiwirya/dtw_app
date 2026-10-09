import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/error_view.dart';
import 'package:dtw_app/core/widgets/order_card.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/core/widgets/success_modal.dart';
import 'package:dtw_app/features/order/data/models/delivery.dart';
import 'package:dtw_app/features/order/data/models/order_models.dart';
import 'package:dtw_app/features/order/presentation/providers/order_provider.dart';
import 'package:dtw_app/features/order/presentation/widgets/detail_screen_parts.dart';
import 'package:dtw_app/features/order/presentation/widgets/order_detail_card.dart';
import 'package:dtw_app/features/order/presentation/widgets/order_success_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The `menu-order-baru-2` frame: the "Detail Pesanan" screen.
///
/// Interpretation (see report): this is a dedicated full order-detail screen —
/// its own "Detail Pesanan" nav bar and a bottom "Ambil Pesanan" CTA — NOT an
/// expanded list-card state and NOT a populated list. It is reached from a
/// Baru card's "Detail" affordance. The CTA claims the real delivery
/// (`POST /deliveries/{id}/claim`) and raises the shared success modal
/// (`berhasil-ditambahkan`); its `onConfirm` returns to the Order home on the
/// Antar sub-tab.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  /// Delivery id to load (a path parameter — see `app_router.dart`).
  final String orderId;

  Future<void> _take(
    BuildContext context,
    WidgetRef ref,
    OrderDetail detail,
  ) async {
    try {
      await ref.read(orderBoardProvider.notifier).claim(orderId);
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
      // Keeps the `berhasil-ditambahkan` frame's title/message/CTA defaults,
      // but the detail rows MUST come from the claimed delivery. Omitting
      // `details` falls back to `SuccessModal`'s hardcoded frame sample
      // (KFC Fried Chicken / Meja A-12 / Budi Santoso), which showed the
      // tenant a confirmation for an order that wasn't the one just taken.
      details: claimedOrderDetails(
        tenantName: detail.tenantName,
        tableName: detail.tableName,
        location: detail.location,
        customerName: detail.customerName,
      ),
      onConfirm: () {
        ref.read(orderTabProvider.notifier).selectStatus(OrderStatus.antar);
        context.goNamed(AppRoutes.order);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(orderBoardProvider);
    final detail = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DetailNavBar(
            title: 'Detail Pesanan',
            fallbackRoute: AppRoutes.order,
          ),
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -8, 0),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildBody(ref, boardAsync, detail),
            ),
          ),
          if (detail != null && detail.status == OrderStatus.baru)
            DetailBottomBar(
              child: PrimaryButton(
                label: 'Ambil Pesanan',
                onPressed: () => _take(context, ref, detail),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    WidgetRef ref,
    AsyncValue<List<Delivery>> boardAsync,
    OrderDetail? detail,
  ) {
    if (detail != null) {
      return ListView(
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
          OrderSummaryCard(detail: detail),
          const SizedBox(height: 16),
          _NoteCard(note: detail.note),
        ],
      );
    }
    if (boardAsync.hasError) {
      return ErrorView(
        message: errorMessage(boardAsync.error!),
        onRetry: () => ref.invalidate(orderBoardProvider),
      );
    }
    if (boardAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Pesanan tidak ditemukan di daftar order.',
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
}

/// "Catatan dari Pelanggan" card.
class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return DetailCard(
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

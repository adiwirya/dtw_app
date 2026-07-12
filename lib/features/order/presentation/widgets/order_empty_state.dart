import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/order_card.dart';
import 'package:flutter/material.dart';
import 'package:obra_icons/obra_icons.dart';

/// Empty-state shown when a Menu Order sub-tab has no orders.
///
// TODO(open-question): the references only exported populated sub-tabs; the
// empty-state copy and iconography are not in the design cache (Open Question:
// empty/error/loading states). This is a sensible placeholder to be replaced
// once the design is provided.
class OrderEmptyState extends StatelessWidget {
  const OrderEmptyState({required this.status, super.key});

  /// The sub-tab this empty view stands in for; selects the message.
  final OrderStatus status;

  IconData get _icon => switch (status) {
        OrderStatus.baru => ObraIcons.clipboard_check,
        OrderStatus.antar => ObraIcons.store,
        OrderStatus.selesai => ObraIcons.circle_check,
      };

  String get _title => switch (status) {
        OrderStatus.baru => 'Belum ada pesanan baru',
        OrderStatus.antar => 'Belum ada pesanan diantar',
        OrderStatus.selesai => 'Belum ada pesanan selesai',
      };

  String get _message => switch (status) {
        OrderStatus.baru => 'Pesanan baru akan muncul di sini.',
        OrderStatus.antar => 'Ambil pesanan untuk mulai mengantar.',
        OrderStatus.selesai => 'Pesanan yang selesai akan tampil di sini.',
      };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.successTint,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(_icon, size: 32, color: AppColors.success700),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _title,
              textAlign: TextAlign.center,
              // TODO(open-question): Open Sans Bold in the cache; not bundled.
              style: const TextStyle(
                color: AppColors.neutral900,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.neutral500,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/order/data/models/order_confirmation.dart';
import 'package:flutter/material.dart';

/// The "Perlu Konfirmasi" card in the Order tab's Konfirmasi section
/// (`menu-order-baru`, node `2286:5910`): the kitchen rejected some items and
/// the customer has to decide. Tapping the card or "Detail" opens
/// the decision screen.
class OrderConfirmationCard extends StatelessWidget {
  const OrderConfirmationCard({
    required this.confirmation,
    required this.onTap,
    super.key,
  });

  final OrderConfirmation confirmation;
  final VoidCallback onTap;

  static const TextStyle _labelStyle = TextStyle(
    color: AppColors.neutral500,
    fontSize: 12,
    height: 1.2,
  );
  static const TextStyle _valueStyle = TextStyle(
    color: AppColors.neutral900,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const TextStyle _mutedStyle = TextStyle(
    color: AppColors.neutral500,
    fontSize: 14,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            offset: Offset(0, 2),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(),
                const SizedBox(height: 12),
                _tile(
                  icon: Icons.storefront_outlined,
                  bg: AppColors.orderTileTenantBg,
                  fg: AppColors.orderTileTenantIcon,
                  label: 'Tenant',
                  value: confirmation.brandName ?? '-',
                ),
                const SizedBox(height: 12),
                _tile(
                  icon: Icons.close,
                  bg: AppColors.dangerTint,
                  fg: AppColors.dangerRed,
                  label: 'Pesanan Tidak Tersedia',
                  value: '${confirmation.rejectedCount} Pesanan',
                ),
                const SizedBox(height: 12),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.neutral100,
                ),
                const SizedBox(height: 12),
                _footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.dangerRed,
            shape: BoxShape.circle,
          ),
          child: SizedBox(width: 12, height: 12),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Perlu Konfirmasi',
            style: TextStyle(
              color: AppColors.dangerRed,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        const Icon(
          Icons.access_time,
          size: 16,
          color: AppColors.neutral500,
        ),
        const SizedBox(width: 8),
        Text(_formatTime(confirmation.createdAt), style: _mutedStyle),
      ],
    );
  }

  Widget _tile({
    required IconData icon,
    required Color bg,
    required Color fg,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Icon(icon, size: 16, color: fg)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: _labelStyle),
              Text(value, style: _valueStyle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    return Row(
      children: [
        const Icon(Icons.person_outline, size: 16, color: AppColors.neutral500),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            confirmation.customerName ?? '-',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.neutral900,
              fontSize: 14,
              height: 1.2,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            width: 4,
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.neutral500,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Text('${confirmation.items.length} Item', style: _mutedStyle),
        const Spacer(),
        const Text(
          'Detail',
          style: TextStyle(
            color: AppColors.successGreen,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.chevron_right,
          size: 16,
          color: AppColors.successGreen,
        ),
      ],
    );
  }

  static String _formatTime(DateTime at) {
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return '$hh:$mm WIB';
  }
}

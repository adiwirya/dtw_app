import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/features/order/data/models/order_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Building blocks of the "Detail Pesanan" screen, shared by the busboy
/// (`OrderDetailScreen`) and tenant (`TenantOrderDetailScreen`) versions —
/// both follow the same Figma frame and differ only in their data and in the
/// action buttons at the bottom.

/// Green nav bar: white status bar over a back arrow + centered title.
///
/// Back pops when it can; otherwise (a deep link, a cold start) it goes to the
/// named [fallbackRoute] — the Order list of whichever shell this is.
class DetailNavBar extends StatelessWidget {
  const DetailNavBar({
    required this.title,
    required this.fallbackRoute,
    super.key,
  });

  final String title;
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.headerGreenTop, AppColors.headerGreenBottom],
        ),
      ),
      child: Column(
        children: [
          // The OS draws the real status bar here; the header runs behind
          // it. A fake `9:41` bar used to sit in this slot, doubling up with
          // the real one on device.
          SizedBox(height: MediaQuery.paddingOf(context).top),
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.goNamed(fallbackRoute);
                      }
                    },
                    icon: const Icon(
                      Icons.chevron_left,
                      color: AppColors.white,
                      size: 28,
                    ),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// "Ringkasan Pesanan" card: title + item count, line items, hairline, total.
///
/// [showItemNotes] adds each item's note (or "Tidak ada catatan") under it, as
/// the tenant frame does.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    required this.detail,
    this.showItemNotes = false,
    super.key,
  });

  final OrderDetail detail;
  final bool showItemNotes;

  static const TextStyle _titleStyle = TextStyle(
    color: AppColors.neutral900,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const TextStyle _mutedStyle = TextStyle(
    color: AppColors.neutral500,
    fontSize: 14,
    height: 1.2,
  );
  static const TextStyle _bodyStyle = TextStyle(
    color: AppColors.neutral900,
    fontSize: 14,
    height: 1.3,
  );
  static const TextStyle _noteStyle = TextStyle(
    color: AppColors.neutral500,
    fontSize: 12,
    height: 1.3,
  );
  static const TextStyle _totalStyle = TextStyle(
    color: AppColors.neutral900,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Ringkasan Pesanan', style: _titleStyle),
              ),
              Text('${detail.itemCount} Item', style: _mutedStyle),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < detail.items.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _lineItem(detail.items[i]),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.neutral100,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Total Pesanan', style: _totalStyle),
              ),
              Text(
                detail.total,
                style: const TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lineItem(OrderLineItem item) {
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text('${item.qty}x', style: _bodyStyle),
              ),
              const SizedBox(width: 8),
              Flexible(child: Text(item.name, style: _bodyStyle)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(item.price, style: _bodyStyle),
      ],
    );
    if (!showItemNotes) return row;

    final note = item.notes?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Row(
            children: [
              const Icon(
                Icons.sticky_note_2_outlined,
                size: 14,
                color: AppColors.neutral500,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  note == null || note.isEmpty ? 'Tidak ada catatan' : note,
                  style: _noteStyle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shared white rounded card used by the detail summary / note sections.
class DetailCard extends StatelessWidget {
  const DetailCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

/// The pinned bottom action bar: a raised white strip holding [child] (one
/// pill button, or a row of two).
class DetailBottomBar extends StatelessWidget {
  const DetailBottomBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: child,
        ),
      ),
    );
  }
}

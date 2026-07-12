import 'package:dtw_app/core/models/completed_order_detail.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:obra_icons/obra_icons.dart';

/// Shared scrollable body for the two completed-order detail pages:
/// `detail-selesai` (Order tab) and `detail-riwayat` (Riwayat tab). The frames
/// are pixel-identical apart from the `Informasi Pesanan` "Tenan" value, so
/// both feature screens delegate here with a different [CompletedOrderDetail].
///
/// Layout (top → bottom): a plain white "Detail Pesanan" nav bar over a
/// scroll of four white cards — the order identity + summary box, "Alur Tugas"
/// timeline, "Informasi Pesanan", and "Rincian item".
class CompletedDetailView extends StatelessWidget {
  const CompletedDetailView({
    required this.detail,
    required this.onBack,
    super.key,
  });

  final CompletedOrderDetail detail;

  /// Back-button handler (pop, or fall back to the parent route).
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailNavBar(onBack: onBack),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _IdentityCard(detail: detail),
                const SizedBox(height: 16),
                _FlowCard(steps: detail.flowSteps),
                const SizedBox(height: 16),
                _InfoCard(rows: detail.infoRows),
                const SizedBox(height: 16),
                _ItemsCard(items: detail.lineItems, total: detail.total),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Shared text styles ------------------------------------------------------

const TextStyle _titleStyle = TextStyle(
  color: AppColors.neutral900,
  fontSize: 16,
  fontWeight: FontWeight.w700,
  height: 1.2,
);
const TextStyle _mutedSmall = TextStyle(
  color: AppColors.neutral500,
  fontSize: 12,
  height: 1.2,
);
const TextStyle _muted14 = TextStyle(
  color: AppColors.neutral500,
  fontSize: 14,
  height: 1.2,
);
const TextStyle _bold14 = TextStyle(
  color: AppColors.neutral900,
  fontSize: 14,
  fontWeight: FontWeight.w700,
  height: 1.2,
);
const TextStyle _body14 = TextStyle(
  color: AppColors.neutral900,
  fontSize: 14,
  height: 1.2,
);

// "Alur Tugas" timeline label/timestamp: the design measures the bold label at
// a 16px line box and the muted timestamp at 14px (Frame 2428/2429 = 30px tall
// with no gap), so use tight line heights that fit the 30px chip-aligned cell.
const TextStyle _flowLabel = TextStyle(
  color: AppColors.neutral900,
  fontSize: 14,
  fontWeight: FontWeight.w700,
  height: 16 / 14,
);
const TextStyle _flowTime = TextStyle(
  color: AppColors.neutral500,
  fontSize: 12,
  height: 14 / 12,
);

/// Plain white nav bar: dark status bar over a back chevron + centered title.
/// The `detail-*` frames drop the green header used by the Order detail screen.
class _DetailNavBar extends StatelessWidget {
  const _DetailNavBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: Column(
        children: [
          const _StatusBar(),
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: onBack,
                    icon: const Icon(
                      // TODO(open-question): cache uses `arrow-left-s-line`;
                      // obra's chevron_left is the closest bundled glyph.
                      ObraIcons.chevron_left,
                      color: AppColors.neutral900,
                      size: 26,
                    ),
                  ),
                ),
                const Text(
                  'Detail Pesanan',
                  // TODO(open-question): Open Sans Bold in the cache; not
                  // bundled (matches the rest of the app).
                  style: TextStyle(
                    color: AppColors.neutral900,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark-on-white status bar (`9:41`). Mirrors the app's other status bars but
/// with dark glyphs to sit on the white detail header.
// TODO(open-question): pixel-exact SVG status glyphs are approximated with
// Material icons until flutter_svg is available.
class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 44,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '9:41',
              style: TextStyle(
                color: AppColors.neutral900,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
            Row(
              children: [
                Icon(Icons.signal_cellular_alt, size: 17),
                SizedBox(width: 6),
                Icon(Icons.wifi, size: 17),
                SizedBox(width: 6),
                Icon(Icons.battery_full, size: 22),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// White rounded card shell shared by every detail section.
class _Card extends StatelessWidget {
  const _Card({required this.child});

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

/// Card 1 — order id, brand row, and the Waktu Antar / Diselesaikan box.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.detail});

  final CompletedOrderDetail detail;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('#${detail.orderId}', style: _titleStyle),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  detail.brandLogoAsset,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(detail.tenantName, style: _titleStyle),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(detail.tableName, style: _muted14),
                        ),
                        _dot(),
                        Flexible(child: Text(detail.location, style: _muted14)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _summaryBox(),
        ],
      ),
    );
  }

  Widget _summaryBox() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.detailInfoBoxBg,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _summaryCell(
                ObraIcons.clock_3,
                'Waktu Antar',
                detail.waktuAntar,
              ),
            ),
            const VerticalDivider(
              width: 25,
              thickness: 1,
              color: AppColors.neutral100,
            ),
            Expanded(
              child: _summaryCell(
                // TODO(open-question): cache uses `calendar-range`; obra's
                // calendar_dates is the closest bundled glyph.
                ObraIcons.calendar_dates,
                'Diselesaikan',
                detail.diselesaikan,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCell(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.neutral500),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: _mutedSmall),
              const SizedBox(height: 4),
              Text(value, style: _bold14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dot() {
    return const Padding(
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
    );
  }
}

/// Card 2 — the "Alur Tugas" timeline (green-tinted chips on a rail).
class _FlowCard extends StatelessWidget {
  const _FlowCard({required this.steps});

  final List<DetailFlowStep> steps;

  static const double _chip = 30;
  static const double _connector = 14;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Alur Tugas', style: _titleStyle),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _rail(),
              const SizedBox(width: 12),
              Expanded(child: _labels()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rail() {
    final children = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      children.add(
        Container(
          width: _chip,
          height: _chip,
          decoration: const BoxDecoration(
            color: AppColors.successTint,
            shape: BoxShape.circle,
          ),
          child: Icon(steps[i].icon, size: 16, color: AppColors.successGreen),
        ),
      );
      if (i < steps.length - 1) {
        children.add(
          Container(width: 1, height: _connector, color: AppColors.neutral100),
        );
      }
    }
    return Column(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _labels() {
    final children = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      children.add(
        SizedBox(
          height: _chip,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(steps[i].label, style: _flowLabel),
              Text(steps[i].timestamp, style: _flowTime),
            ],
          ),
        ),
      );
      if (i < steps.length - 1) {
        children.add(const SizedBox(height: _connector));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

/// Card 3 — "Informasi Pesanan" label/value rows.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<DetailInfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Informasi Pesanan', style: _titleStyle),
          const SizedBox(height: 16),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(rows[i].label, style: _muted14)),
                const SizedBox(width: 12),
                Text(rows[i].value, textAlign: TextAlign.right, style: _body14),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Card 4 — "Rincian item" line items, hairline, and the green total.
class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.items, required this.total});

  final List<DetailLineItem> items;
  final String total;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Rincian item', style: _titleStyle),
          const SizedBox(height: 16),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _lineItem(items[i]),
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
            children: [
              const Expanded(child: Text('Total', style: _body14)),
              const SizedBox(width: 12),
              Text(
                total,
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

  Widget _lineItem(DetailLineItem item) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              SizedBox(width: 24, child: Text('${item.qty}x', style: _body14)),
              const SizedBox(width: 8),
              Flexible(child: Text(item.name, style: _body14)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(item.price, style: _body14),
      ],
    );
  }
}

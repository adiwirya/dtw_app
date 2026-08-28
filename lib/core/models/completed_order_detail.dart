import 'package:flutter/widgets.dart';

/// One step in the "Alur Tugas" (task flow) timeline on the completed-order
/// detail (`detail-selesai` / `detail-riwayat` `Frame 2607`): a tinted circular
/// glyph with a bold label over a muted timestamp.
@immutable
class DetailFlowStep {
  const DetailFlowStep({
    required this.icon,
    required this.label,
    required this.timestamp,
  });

  /// Glyph shown in the green-tinted chip on the rail.
  final IconData icon;

  /// Bold step name, e.g. `Diambil`, `Diantar`, `Sampai Dimeja`.
  final String label;

  /// Muted timestamp, e.g. `12 Mei 2026, 10:27`.
  final String timestamp;
}

/// One label/value row in the "Informasi Pesanan" card (`Frame 2438`): a muted
/// left label and a dark right-aligned value.
@immutable
class DetailInfoRow {
  const DetailInfoRow({required this.label, required this.value});

  /// Left label, e.g. `Tenan`, `Meja`, `Zona`.
  final String label;

  /// Right value, e.g. `Rp35.000`, `A-12`, `Downtown`.
  final String value;
}

/// One priced line item in the "Rincian item" card (`Frame 2608`).
@immutable
class DetailLineItem {
  const DetailLineItem({
    required this.qty,
    required this.name,
    required this.price,
  });

  /// Quantity, rendered as `<qty>x`.
  final int qty;

  /// Menu item name, e.g. `Paket Super Besar`.
  final String name;

  /// Formatted price, e.g. `Rp35.000`.
  final String price;
}

/// Backing data for the completed-order detail pages `detail-selesai`
/// (completed-order detail, Order tab) and `detail-riwayat` (history entry
/// detail, Riwayat tab). The two frames share an identical layout — only the
/// `Informasi Pesanan` "Tenan" value differs — so both feed the same
/// `CompletedDetailView` with a different [infoRows] list.
///
/// Open question: this is a UI-only mock value object decoupled from any
/// repository/DTO — the detail data source is unresolved (Open Question 2 /
/// work item L5). When the real source lands, map the domain entity onto this.
@immutable
class CompletedOrderDetail {
  const CompletedOrderDetail({
    required this.orderId,
    required this.tenantName,
    required this.tableName,
    required this.location,
    required this.waktuAntar,
    required this.diselesaikan,
    required this.flowSteps,
    required this.infoRows,
    required this.lineItems,
    required this.total,
    this.brandLogoAsset,
  });

  /// Order number without the leading `#`. Rendered as `#<orderId>`.
  final String orderId;

  /// Source tenant/merchant name, e.g. `KFC Fried Chicken` (card title).
  final String tenantName;

  /// Asset key for the brand logo chip.
  ///
  /// Always null today, and there is no bundled per-brand logo to point it at:
  /// a delivery can span several brands, so there is no single logo to show
  /// and the view falls back to a plain placeholder tile. Kept as a seam for
  /// when a single-brand delivery gets one.
  final String? brandLogoAsset;

  /// Destination table label, e.g. `Meja A-12`.
  final String tableName;

  /// Destination area/zone, e.g. `Downtown`.
  final String location;

  /// Delivery duration shown in the summary box, e.g. `4 Menit`.
  final String waktuAntar;

  /// Completion timestamp shown in the summary box, e.g. `12 Mei 2026, 10:45`.
  final String diselesaikan;

  /// The "Alur Tugas" timeline steps, top to bottom.
  final List<DetailFlowStep> flowSteps;

  /// The "Informasi Pesanan" label/value rows.
  final List<DetailInfoRow> infoRows;

  /// The "Rincian item" priced line items.
  final List<DetailLineItem> lineItems;

  /// Formatted grand total, e.g. `Rp40.000`.
  final String total;
}

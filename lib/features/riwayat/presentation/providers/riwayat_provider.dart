import 'package:dtw_app/core/models/completed_order_detail.dart';
import 'package:dtw_app/features/riwayat/data/models/riwayat_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obra_icons/obra_icons.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'riwayat_provider.g.dart';

// TODO(open-question): the Riwayat history data source, empty / loading /
// error states, and pagination are all unresolved (Open Questions 2/4/5).
// Everything below is hard-coded, in-memory mock data harvested from the
// `riwayat-*` Figma references. When the real source lands, replace this
// synchronous provider with an async repository fetch (`Future<List<
// RiwayatDayGroup>>` backed by dio, per knowledge/riverpod-patterns.md) keyed
// by [RiwayatRange], and have the screen consume the AsyncValue.

/// Currently selected Riwayat date tab, as an index into
/// `[hariIni, kemarin, tujuhHari]`. Kept as app state (not screen-local) so the
/// `/riwayat/kemarin` and `/riwayat/7-hari` route deep-links can switch the
/// in-place tab. Mirrors the Order tab provider.
@riverpod
class RiwayatTab extends _$RiwayatTab {
  @override
  int build() => 0;

  /// Select by index (0 = Hari Ini, 1 = Kemarin, 2 = 7 Hari Terakhir).
  // ignore: use_setters_to_change_properties
  void select(int index) => state = index;

  /// Select by [RiwayatRange].
  void selectRange(RiwayatRange range) => state = range.index;
}

// --- Mock day groups (harvested from the riwayat-* references) -------------

const _hariIniGroup = RiwayatDayGroup(
  date: '12 Mei 2026',
  entries: [
    RiwayatEntry(
      time: '10:45',
      statusLabel: 'Selesai',
      tenantName: 'KFC Fried Chicken',
      tableName: 'Meja A-12',
      location: 'Downtown',
    ),
    RiwayatEntry(
      time: '10:45',
      statusLabel: 'Selesai',
      tenantName: 'Starbucks',
      tableName: 'Meja A-12',
      location: 'Downtown',
    ),
    RiwayatEntry(
      time: '10:45',
      statusLabel: 'Selesai',
      tenantName: 'J.CO Donuts',
      tableName: 'Meja A-12',
      location: 'Downtown',
    ),
  ],
);

const _kemarinGroup = RiwayatDayGroup(
  date: '11 Mei 2026',
  entries: [
    RiwayatEntry(
      time: '10:45',
      statusLabel: 'Selesai',
      tenantName: 'Solaria',
      tableName: 'Meja A-12',
      location: 'Downtown',
    ),
    RiwayatEntry(
      time: '10:45',
      statusLabel: 'Selesai',
      tenantName: 'Starbucks',
      tableName: 'Meja A-12',
      location: 'Downtown',
    ),
  ],
);

/// Mock history for a [RiwayatRange].
///
/// - [RiwayatRange.hariIni] → today's single day group.
/// - [RiwayatRange.kemarin] → yesterday's single day group.
/// - [RiwayatRange.tujuhHari] → both groups stacked (newest first), matching
///   the multi-day `riwayat-7-hari` reference.
@riverpod
List<RiwayatDayGroup> riwayatDays(Ref ref, RiwayatRange range) {
  switch (range) {
    case RiwayatRange.hariIni:
      return const [_hariIniGroup];
    case RiwayatRange.kemarin:
      return const [_kemarinGroup];
    case RiwayatRange.tujuhHari:
      return const [_hariIniGroup, _kemarinGroup];
  }
}

// TODO(open-question): the history-entry detail data source is unresolved (Open
// Question 2 / work item L5). This is hard-coded, in-memory mock data harvested
// from the `detail-riwayat` reference; when the real source lands, replace this
// synchronous provider with an async repository fetch keyed by entry id and
// have the screen consume the AsyncValue.
/// Mock detail for the `detail-riwayat` (history entry detail) page. The frame
/// is identical to `detail-selesai` except the `Informasi Pesanan` "Tenan"
/// value, which here shows the tenant subtotal (`Rp35.000`).
@riverpod
CompletedOrderDetail riwayatDetail(Ref ref) {
  return const CompletedOrderDetail(
    orderId: '92842',
    tenantName: 'KFC Fried Chicken',
    brandLogoAsset: 'assets/images/brand-kfc.png',
    tableName: 'Meja A-12',
    location: 'Downtown',
    waktuAntar: '4 Menit',
    diselesaikan: '12 Mei 2026, 10:45',
    flowSteps: [
      DetailFlowStep(
        // TODO(open-question): no obra concierge-bell glyph; approximated.
        icon: Icons.room_service_outlined,
        label: 'Diambil',
        timestamp: '12 Mei 2026, 10:27',
      ),
      DetailFlowStep(
        // TODO(open-question): no obra hand-platter glyph; approximated.
        icon: Icons.restaurant_outlined,
        label: 'Diantar',
        timestamp: '12 Mei 2026, 10:30',
      ),
      DetailFlowStep(
        icon: ObraIcons.circle_check,
        label: 'Sampai Dimeja',
        timestamp: '12 Mei 2026, 10:45',
      ),
    ],
    infoRows: [
      DetailInfoRow(label: 'Tenan', value: 'Rp35.000'),
      DetailInfoRow(label: 'Meja', value: 'A-12'),
      DetailInfoRow(label: 'Zona', value: 'Downtown'),
      DetailInfoRow(label: 'Pelanggan', value: 'Budi Santoso'),
      DetailInfoRow(label: 'Jumlah Item', value: '2 Item'),
      DetailInfoRow(label: 'Catatan Tenan', value: '-'),
    ],
    lineItems: [
      DetailLineItem(qty: 1, name: 'Paket Super Besar', price: 'Rp35.000'),
      DetailLineItem(qty: 1, name: 'Es Lemon Tea', price: 'Rp5.000'),
    ],
    total: 'Rp40.000',
  );
}

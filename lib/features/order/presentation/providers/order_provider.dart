import 'package:dtw_app/core/models/completed_order_detail.dart';
import 'package:dtw_app/core/widgets/order_card.dart';
import 'package:dtw_app/features/order/data/models/order_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obra_icons/obra_icons.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'order_provider.g.dart';

// TODO(open-question): the order data source, real state transitions, empty /
// error / loading, and pagination are all unresolved (Open Questions 2–5).
// Everything below is hard-coded, in-memory mock data harvested from the
// `menu-order-*` Figma references, and the Baru → Antar → Selesai movement is a
// UI-only mock. When the real source lands, replace these synchronous providers
// with an async repository fetch (`Future<OrderBoard>` backed by dio, per
// knowledge/riverpod-patterns.md) and have the screen consume the AsyncValue.

/// The three header summary stats on the Order home (`menu-order-baru`).
@riverpod
List<OrderHeaderStat> orderHeaderStats(Ref ref) {
  return const [
    OrderHeaderStat(
      value: '95%',
      label: 'Ketepatan Waktu',
      color: 0xFF10A760, // AppColors.successGreen
    ),
    OrderHeaderStat(
      value: '12',
      label: 'Pesanan Selesai',
      color: 0xFF3B82F6, // AppColors.accentBlue
    ),
    OrderHeaderStat(
      value: '4.9',
      label: 'Rating Pelanggan',
      color: 0xFFE9A23B, // AppColors.accentAmber
      showStar: true,
    ),
  ];
}

/// Currently selected Order sub-tab, as an index into
/// `[baru, antar, selesai]`. Kept as app state (not screen-local) so route
/// deep-links (`/order/antar`, `/order/selesai`) and the success-modal
/// `onConfirm` can switch the in-place tab.
@riverpod
class OrderTab extends _$OrderTab {
  @override
  int build() => 0;

  /// Select by index (0 = Baru, 1 = Antar, 2 = Selesai).
  // ignore: use_setters_to_change_properties
  void select(int index) => state = index;

  /// Select by [OrderStatus].
  void selectStatus(OrderStatus status) => state = status.index;
}

/// The mock Menu Order board, with UI-only Baru → Antar → Selesai transitions.
@riverpod
class OrderBoardNotifier extends _$OrderBoardNotifier {
  @override
  OrderBoard build() {
    return const OrderBoard(
      baru: [
        OrderCardData(
          orderId: '92842',
          time: '10:31 WIB',
          tenantName: 'KFC Fried Chicken',
          tableName: 'Meja A-12',
          location: 'Downtown',
          customerName: 'Budi Santoso',
          itemCount: 2,
          status: OrderStatus.baru,
        ),
        OrderCardData(
          orderId: '92842',
          time: '10:31 WIB',
          tenantName: 'Solaria',
          tableName: 'Meja A-12',
          location: 'Downtown',
          customerName: 'Budi Santoso',
          itemCount: 3,
          status: OrderStatus.baru,
        ),
      ],
      antar: [
        OrderCardData(
          orderId: '92842',
          time: '10:31 WIB',
          tenantName: 'KFC Fried Chicken',
          tableName: 'Meja A-12',
          location: 'Downtown',
          customerName: 'Budi Santoso',
          itemCount: 2,
          status: OrderStatus.antar,
        ),
        OrderCardData(
          orderId: '92842',
          time: '10:31 WIB',
          tenantName: 'Solaria',
          tableName: 'Meja A-12',
          location: 'Downtown',
          customerName: 'Septian Adityo',
          itemCount: 2,
          status: OrderStatus.antar,
        ),
      ],
      selesai: [
        OrderCardData(
          orderId: '92842',
          time: '10:31 WIB',
          tenantName: 'KFC Fried Chicken',
          tableName: 'Meja A-12',
          location: 'Downtown',
          customerName: 'Budi Santoso',
          itemCount: 3,
          status: OrderStatus.selesai,
          deliveredDate: '12 Mei 2024',
          deliveredTime: '10:45 WIB',
        ),
      ],
    );
  }

  /// Promote the Baru order at [index] to the Antar tab (the detail screen's
  /// "Ambil Pesanan" action). UI-only mock.
  void takeBaru(int index) {
    final board = state;
    if (index < 0 || index >= board.baru.length) return;
    final taken = _withStatus(board.baru[index], OrderStatus.antar);
    state = board.copyWith(
      baru: [...board.baru]..removeAt(index),
      antar: [...board.antar, taken],
    );
  }

  /// Promote the Antar order at [index] to the Selesai tab (the "Sampai dimeja"
  /// action). UI-only mock.
  void deliverAntar(int index) {
    final board = state;
    if (index < 0 || index >= board.antar.length) return;
    final src = board.antar[index];
    final delivered = OrderCardData(
      orderId: src.orderId,
      time: src.time,
      tenantName: src.tenantName,
      tableName: src.tableName,
      location: src.location,
      customerName: src.customerName,
      itemCount: src.itemCount,
      status: OrderStatus.selesai,
      deliveredDate: '12 Mei 2024',
      deliveredTime: '10:45 WIB',
    );
    state = board.copyWith(
      antar: [...board.antar]..removeAt(index),
      selesai: [...board.selesai, delivered],
    );
  }

  OrderCardData _withStatus(OrderCardData d, OrderStatus status) {
    return OrderCardData(
      orderId: d.orderId,
      time: d.time,
      tenantName: d.tenantName,
      tableName: d.tableName,
      location: d.location,
      customerName: d.customerName,
      itemCount: d.itemCount,
      status: status,
      deliveredDate: d.deliveredDate,
      deliveredTime: d.deliveredTime,
    );
  }
}

/// Mock order detail for the `menu-order-baru-2` screen. Parameterised by order
/// id; only the single harvested mock (`92842`) exists for now.
@riverpod
OrderDetail orderDetail(Ref ref, String orderId) {
  return const OrderDetail(
    orderId: '92842',
    time: '10:31 WIB',
    tenantName: 'KFC Fried Chicken',
    tableName: 'Meja A-12',
    location: 'Downtown',
    customerName: 'Budi Santoso',
    itemCount: 3,
    items: [
      OrderLineItem(qty: 1, name: 'Paket Super Besar', price: 'Rp35.000'),
      OrderLineItem(qty: 1, name: 'Es Lemon Tea', price: 'Rp5.000'),
    ],
    total: 'Rp40.000',
    note: '-',
  );
}

// TODO(open-question): the completed-order detail data source is unresolved
// (Open Question 2 / work item L5). This is hard-coded, in-memory mock data
// harvested from the `detail-selesai` reference; when the real source lands,
// replace this synchronous provider with an async repository fetch keyed by
// order id and have the screen consume the AsyncValue.
/// Mock detail for the `detail-selesai` (completed-order detail) page. The
/// frame is identical to `detail-riwayat` except the `Informasi Pesanan`
/// "Tenan" value, which here shows the tenant name (`KFC Fried Chicken`).
@riverpod
CompletedOrderDetail completedOrderDetail(Ref ref) {
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
      DetailInfoRow(label: 'Tenan', value: 'KFC Fried Chicken'),
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

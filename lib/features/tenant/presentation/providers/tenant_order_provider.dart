import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tenant_order_provider.g.dart';

// TODO(open-question): the tenant order data source and the real
// Baru → Diproses → Selesai state transitions are unresolved (an Open
// Question on this work item). Everything below is hard-coded, in-memory mock
// data harvested from the `menu-order-baru` / `menu-diproses` / `selesai`
// tenant Figma references, and accept()/markReady() are UI-only mock
// transitions. When the real source lands, replace this synchronous notifier
// with an async repository fetch (`Future<List<IncomingOrderData>>` backed by
// dio, per knowledge/riverpod-patterns.md) and have the screen consume the
// resulting AsyncValue.
const List<IncomingOrderData> _mockTenantOrders = [
  // --- Order Baru (menu-order-baru: two cards) ---
  IncomingOrderData(
    orderId: '92842',
    tableName: 'Meja A-12',
    time: '10:36 WIB',
    status: IncomingOrderStatus.baru,
    items: [
      OrderLineItem(name: 'Paket Super Besar', price: 'Rp35.000'),
      OrderLineItem(name: 'Es Lemon Tea', price: 'Rp5.000'),
    ],
    total: 'Rp40.000',
  ),
  IncomingOrderData(
    orderId: '92842',
    tableName: 'Meja A-14',
    time: '10:36 WIB',
    status: IncomingOrderStatus.baru,
    items: [
      OrderLineItem(name: 'Paket Komplit', price: 'Rp32.000'),
    ],
    total: 'Rp32.000',
    note: 'extra sauce ya..',
  ),
  // --- Diproses (menu-diproses: one card, both items) ---
  IncomingOrderData(
    orderId: '92842',
    tableName: 'Meja A-12',
    time: '10:36 WIB',
    status: IncomingOrderStatus.diproses,
    items: [
      OrderLineItem(name: 'Paket Super Besar', price: 'Rp35.000'),
      OrderLineItem(name: 'Es Lemon Tea', price: 'Rp5.000'),
    ],
    total: 'Rp40.000',
  ),
  // --- Selesai (selesai: one card, no actions) ---
  IncomingOrderData(
    orderId: '92842',
    tableName: 'Meja A-12',
    time: '10:36 WIB',
    status: IncomingOrderStatus.selesai,
    items: [
      OrderLineItem(name: 'Paket Super Besar', price: 'Rp35.000'),
      OrderLineItem(name: 'Es Lemon Tea', price: 'Rp5.000'),
    ],
    total: 'Rp40.000',
  ),
];

/// The mock tenant "Order" board: a flat list of [IncomingOrderData] spanning
/// the three sub-tabs (`baru` / `diproses` / `selesai`). The screen filters by
/// [IncomingOrderData.status] to render each sub-tab in place.
///
/// A class-based `@riverpod` notifier so mutations go through `state`
/// (per this work item's Riverpod constraint). [accept] and [markReady] are
/// UI-only mock transitions.
@riverpod
class TenantOrderBoard extends _$TenantOrderBoard {
  @override
  List<IncomingOrderData> build() => _mockTenantOrders;

  /// UI-only: promote the first `Baru` order matching [orderId] to `Diproses`
  /// (the card's "Terima" action). No-op if no such order exists.
  void accept(String orderId) => _transition(
        orderId,
        from: IncomingOrderStatus.baru,
        to: IncomingOrderStatus.diproses,
      );

  /// UI-only: promote the first `Diproses` order matching [orderId] to
  /// `Selesai` (the card's "Siap Diambil" action). No-op if none matches.
  void markReady(String orderId) => _transition(
        orderId,
        from: IncomingOrderStatus.diproses,
        to: IncomingOrderStatus.selesai,
      );

  /// UI-only: confirm a (partial) rejection of the first `Baru` order matching
  /// [orderId]. The tenant marked one or more items unavailable on the
  /// `pesanan-ditolak` screen; [rejectedItemNames] carries those names and
  /// [reason] the shared rejection reason captured in the `alasan-penolakan`
  /// modal.
  ///
  /// Per the prototype flow the order still proceeds with its remaining
  /// available items, so the confirmed order advances Baru → Diproses (the
  /// success modal then lands on the Diproses sub-tab). No-op if no matching
  /// Baru order exists.
  // TODO(open-question): real partial-rejection semantics (which items the
  // customer keeps, whether a fully-rejected order is cancelled vs. processed,
  // where [reason]/[rejectedItemNames] are persisted) are unresolved. This is a
  // UI-only mock: it records nothing and simply advances the order to Diproses.
  void reject(
    String orderId, {
    required String reason,
    List<String>? rejectedItemNames,
  }) =>
      _transition(
        orderId,
        from: IncomingOrderStatus.baru,
        to: IncomingOrderStatus.diproses,
      );

  void _transition(
    String orderId, {
    required IncomingOrderStatus from,
    required IncomingOrderStatus to,
  }) {
    final index = state.indexWhere(
      (order) => order.orderId == orderId && order.status == from,
    );
    if (index == -1) return;
    state = [
      for (var i = 0; i < state.length; i++)
        if (i == index) _withStatus(state[i], to) else state[i],
    ];
  }

  IncomingOrderData _withStatus(
    IncomingOrderData order,
    IncomingOrderStatus status,
  ) {
    return IncomingOrderData(
      orderId: order.orderId,
      tableName: order.tableName,
      time: order.time,
      status: status,
      items: order.items,
      total: order.total,
      note: order.note,
    );
  }
}

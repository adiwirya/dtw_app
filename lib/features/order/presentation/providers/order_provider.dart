import 'dart:async';

import 'package:dtw_app/core/models/completed_order_detail.dart';
import 'package:dtw_app/core/realtime/busboy_realtime_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/core/widgets/order_card.dart';
import 'package:dtw_app/features/order/data/models/delivery.dart';
import 'package:dtw_app/features/order/data/models/order_models.dart';
import 'package:dtw_app/features/order/data/repositories/busboy_delivery_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'order_provider.g.dart';

// The Order board (list + claim + complete) and the completed-order detail
// below are real, backed by `BusboyDeliveryRepository`.

/// Derives the three Menu Order sub-tab lists from the raw fetched
/// deliveries — pure mapping, kept out of the notifier so it's trivially
/// testable on its own.
OrderBoard orderBoardFrom(List<Delivery> deliveries) {
  final byStatus = <DeliveryStatus, List<OrderCardData>>{
    for (final status in DeliveryStatus.values) status: [],
  };
  for (final delivery in deliveries) {
    byStatus[delivery.status]!.add(delivery.toOrderCardData());
  }
  return OrderBoard(
    baru: byStatus[DeliveryStatus.pendingPickup]!,
    antar: byStatus[DeliveryStatus.claimed]!,
    selesai: byStatus[DeliveryStatus.delivered]!,
  );
}

/// Counts today's delivered deliveries out of [deliveries] — pure mapping,
/// kept out of the provider so it's trivially testable on its own.
int completedTodayCount(List<Delivery> deliveries, DateTime today) {
  final day = DateTime(today.year, today.month, today.day);
  return deliveries
      .where((d) => d.status == DeliveryStatus.delivered && d.riwayatDay == day)
      .length;
}

/// The three header summary stats on the Order home (`menu-order-baru`).
/// Only "Pesanan Selesai" has real backing data (today's delivered count off
/// the same board this screen already renders) — the busboy API has no
/// on-time-rate or customer-rating endpoint, so those two stay `-` rather
/// than a fabricated number.
@riverpod
List<OrderHeaderStat> orderHeaderStats(Ref ref) {
  final deliveries = ref.watch(orderBoardNotifierProvider).valueOrNull;
  final completedToday = deliveries == null
      ? null
      : completedTodayCount(deliveries, DateTime.now());

  return [
    const OrderHeaderStat(
      value: '-',
      label: 'Ketepatan Waktu',
      color: 0xFF10A760, // AppColors.successGreen
    ),
    OrderHeaderStat(
      value: completedToday == null ? '-' : '$completedToday',
      label: 'Pesanan Selesai',
      color: 0xFF3B82F6, // AppColors.accentBlue
    ),
    const OrderHeaderStat(
      value: '-',
      label: 'Rating Pelanggan',
      color: 0xFFE9A23B, // AppColors.accentAmber
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

/// The busboy's raw delivery list, fetched once from
/// `GET /api/v1/busboy/deliveries` and kept live via
/// `BusboyRealtimeService.deliveryCreated` (`private-zone.<zoneId>`,
/// `delivery.created`) — no polling. The Order screen's three sub-tabs are
/// [orderBoardFrom] projections of this same list, and [orderDetailProvider]
/// looks a single delivery up out of it, so `claim`/`deliver` only need to
/// mutate this one list for every dependent view to update together.
@riverpod
class OrderBoardNotifier extends _$OrderBoardNotifier {
  StreamSubscription<Map<String, dynamic>>? _deliveryCreatedSubscription;

  @override
  Future<List<Delivery>> build() async {
    final zoneId =
        await ref.watch(localStorageProvider).read(busboyZoneIdStorageKey);
    if (zoneId == null) {
      throw StateError('OrderBoardNotifier requires a zone-scoped session');
    }

    final repository = ref.watch(busboyDeliveryRepositoryProvider);
    final realtime = ref.watch(busboyRealtimeServiceProvider);

    ref.onDispose(() {
      unawaited(_deliveryCreatedSubscription?.cancel() ?? Future.value());
    });

    // Mirrors `TenantOrderBoard`: `state.value` is null until the initial
    // fetch resolves, so events that arrive during that window are buffered
    // here (keyed by id, to collapse a same-delivery redelivery) and folded
    // into the fetched list once it's ready — see that class for the fuller
    // rationale.
    final pendingDuringFetch = <String, Delivery>{};
    var initialFetchSettled = false;
    _deliveryCreatedSubscription = realtime.deliveryCreated.listen((payload) {
      final delivery = Delivery.fromJson(payload);
      if (state.value == null && !initialFetchSettled) {
        pendingDuringFetch[delivery.id] = delivery;
      } else {
        _onDeliveryCreated(delivery);
      }
    });

    final List<Delivery> deliveries;
    try {
      deliveries = await repository.fetchDeliveries();
    } finally {
      initialFetchSettled = true;
    }
    if (pendingDuringFetch.isEmpty) return deliveries;

    final fetchedIds = deliveries.map((d) => d.id).toSet();
    final fresh = pendingDuringFetch.values.where(
      (d) => !fetchedIds.contains(d.id),
    );
    return [...fresh, ...deliveries];
  }

  void _onDeliveryCreated(Delivery delivery) {
    final current = state.value;
    if (current == null) return;
    if (current.any((d) => d.id == delivery.id)) return;
    state = AsyncData([delivery, ...current]);
  }

  /// Claims a PENDING_PICKUP delivery (the detail screen's "Ambil Pesanan"
  /// action) — `POST /deliveries/{id}/claim`.
  Future<void> claim(String deliveryId) => _transition(
        deliveryId,
        DeliveryStatus.claimed,
        (repository) => repository.claim(deliveryId),
      );

  /// Completes a CLAIMED delivery (the "Sampai dimeja" action) —
  /// `POST /deliveries/{id}/complete`.
  Future<void> deliver(String deliveryId) => _transition(
        deliveryId,
        DeliveryStatus.delivered,
        (repository) => repository.complete(deliveryId),
      );

  Future<void> _transition(
    String deliveryId,
    DeliveryStatus target,
    Future<void> Function(BusboyDeliveryRepository repository) call,
  ) async {
    final current = state.value;
    if (current == null) {
      throw StateError(
        'OrderBoardNotifier: cannot move delivery $deliveryId to $target — '
        'the board has not finished loading',
      );
    }
    final index = current.indexWhere((d) => d.id == deliveryId);
    if (index == -1) {
      throw StateError(
        'OrderBoardNotifier: cannot move delivery $deliveryId to $target — '
        'it is not on the board',
      );
    }
    final previous = current[index];
    state = AsyncData([
      for (final d in current)
        if (d.id == deliveryId) previous.copyWith(status: target) else d,
    ]);

    try {
      await call(ref.read(busboyDeliveryRepositoryProvider));
    } on Object catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

/// Looks [orderId] (a delivery id) up out of the same list
/// [orderBoardNotifierProvider] holds — null while the board is still
/// loading, has errored, or the delivery isn't (or is no longer) on it.
@riverpod
OrderDetail? orderDetail(Ref ref, String orderId) {
  final deliveries = ref.watch(orderBoardNotifierProvider).valueOrNull;
  if (deliveries == null) return null;
  for (final delivery in deliveries) {
    if (delivery.id == orderId) return delivery.toOrderDetail();
  }
  return null;
}

/// Looks [orderId] up out of [orderBoardNotifierProvider] for the
/// `detail-selesai` (completed-order detail) page — null while the board is
/// still loading, has errored, or the delivery isn't on it.
@riverpod
CompletedOrderDetail? completedOrderDetail(Ref ref, String orderId) {
  final deliveries = ref.watch(orderBoardNotifierProvider).valueOrNull;
  if (deliveries == null) return null;
  for (final delivery in deliveries) {
    if (delivery.id == orderId) return delivery.toCompletedOrderDetail();
  }
  return null;
}

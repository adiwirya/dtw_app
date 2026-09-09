import 'dart:async';

import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/flavor.dart';
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
/// `BusboyRealtimeService`'s `delivery.created`/`delivery.claimed`/
/// `delivery.completed` (`private-zone.<zoneId>`) — no polling. The Order
/// screen's three sub-tabs are [orderBoardFrom] projections of this same
/// list, and [orderDetailProvider] looks a single delivery up out of it, so
/// `claim`/`deliver` only need to mutate this one list for every dependent
/// view to update together.
@riverpod
class OrderBoardNotifier extends _$OrderBoardNotifier {
  StreamSubscription<Map<String, dynamic>>? _deliveryCreatedSubscription;
  StreamSubscription<Map<String, dynamic>>? _deliveryClaimedSubscription;
  StreamSubscription<Map<String, dynamic>>? _deliveryCompletedSubscription;

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
      unawaited(_deliveryClaimedSubscription?.cancel() ?? Future.value());
      unawaited(_deliveryCompletedSubscription?.cancel() ?? Future.value());
    });

    // Mirrors `TenantOrderBoard`: `state.value` is null until the initial
    // fetch resolves, so events that arrive during that window are buffered
    // here (keyed by id, to collapse a same-delivery redelivery) and folded
    // into the fetched list once it's ready — see that class for the fuller
    // rationale. Only `delivery.created` needs this: a claimed/completed
    // delivery already existed before this window opened, so the fetch below
    // returns its current status regardless — see `_onDeliveryUpdated`.
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
    _deliveryClaimedSubscription = realtime.deliveryClaimed.listen(
      (payload) => _onDeliveryUpdated(Delivery.fromJson(payload)),
    );
    _deliveryCompletedSubscription = realtime.deliveryCompleted.listen(
      (payload) => _onDeliveryUpdated(Delivery.fromJson(payload)),
    );

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

  /// Replaces a delivery already on the board with [delivery] — the
  /// `delivery.claimed`/`delivery.completed` handler. Covers another
  /// busboy's claim/complete (this device would otherwise never learn about
  /// it — see `docs/busboy-missing-endpoints.md` item 3) as well as this same
  /// device's own action, which [_transition] already applied optimistically;
  /// replacing it again with the server's copy is a no-op in that case.
  void _onDeliveryUpdated(Delivery delivery) {
    final current = state.value;
    if (current == null) return;
    final index = current.indexWhere((d) => d.id == delivery.id);
    if (index == -1) return;
    state = AsyncData([
      for (final d in current) if (d.id == delivery.id) delivery else d,
    ]);
  }

  /// How many deliveries this busboy may have CLAIMED (not yet delivered) at
  /// once — enforced client-side in [claim], rejected before the API call.
  /// Purely a client-side courtesy for now: a modified/bypassed client could
  /// still claim past this, so the server should eventually enforce it too.
  static const maxActiveDeliveries = 2;

  /// Claims a PENDING_PICKUP delivery (the detail screen's "Ambil Pesanan"
  /// action) — `POST /deliveries/{id}/claim`. Rejects locally, without
  /// calling the API, once this busboy already has [maxActiveDeliveries]
  /// deliveries claimed and not yet delivered.
  Future<void> claim(String deliveryId) async {
    final current = state.value;
    final myUserId = ref.read(sessionUserIdProvider);
    if (current != null) {
      final activeCount = current
          .where(
            (d) =>
                d.status == DeliveryStatus.claimed &&
                d.busboyUserId == myUserId,
          )
          .length;
      if (activeCount >= maxActiveDeliveries) {
        throw ApiException(
          message: 'Kamu sudah punya $maxActiveDeliveries order yang sedang '
              'diantar. Selesaikan salah satu dulu sebelum ambil order baru.',
        );
      }
    }
    return _transition(
      deliveryId,
      DeliveryStatus.claimed,
      (repository) => repository.claim(deliveryId),
      // Stamps this busboy's own id on the optimistic update too, so a
      // second `claim` right after (before the server confirms or the
      // `delivery.claimed` broadcast echoes back) counts this one correctly
      // against the limit above.
      applyOptimistic: (previous) => previous.copyWith(
        status: DeliveryStatus.claimed,
        busboyUserId: myUserId,
      ),
    );
  }

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
    Future<void> Function(BusboyDeliveryRepository repository) call, {
    Delivery Function(Delivery previous)? applyOptimistic,
  }) async {
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
    final updated =
        (applyOptimistic ?? (d) => d.copyWith(status: target))(previous);
    state = AsyncData([
      for (final d in current) if (d.id == deliveryId) updated else d,
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

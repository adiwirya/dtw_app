import 'dart:async';

import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_order_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tenant_order_provider.g.dart';

/// The tenant "Order" board: fetches once from the real API, then stays
/// live via `TenantRealtimeService.orderCreated` — no polling. [accept],
/// [reject] and [markReady] optimistically update local state, call the
/// repository, and revert-and-rethrow on failure so the screen can show an
/// error (see `TenantOrderScreen`).
///
/// AutoDisposes (the `@riverpod` default) rather than `keepAlive: true`:
/// `TenantOrderScreen` continuously watches this provider while mounted, so
/// autoDispose never fires mid-session in production, and tearing the board
/// down on logout/navigate-away is what makes switching branches safe —
/// nothing else invalidates this provider on logout, so a `keepAlive`
/// notifier would keep the previous branch's stale order list (and its
/// still-open realtime subscription would keep appending the *new* branch's
/// live events onto it).
@riverpod
class TenantOrderBoard extends _$TenantOrderBoard {
  StreamSubscription<Map<String, dynamic>>? _orderCreatedSubscription;
  StreamSubscription<void>? _reconnectedSubscription;
  int? _lastBroadcastEventId;
  late String _branchId;

  @override
  Future<List<TenantOrder>> build() async {
    final branchId =
        await ref.read(localStorageProvider).read(tenantBranchIdStorageKey);
    if (branchId == null) {
      throw StateError('TenantOrderBoard requires a tenant-scoped session');
    }
    _branchId = branchId;

    final repository = ref.watch(tenantOrderRepositoryProvider);
    final realtime = ref.watch(tenantRealtimeServiceProvider);

    ref.onDispose(() {
      unawaited(_orderCreatedSubscription?.cancel() ?? Future.value());
      unawaited(_reconnectedSubscription?.cancel() ?? Future.value());
    });

    // `state.value` is null until the initial fetch below resolves, so
    // `_onOrderCreated` (which bails out when `state.value == null`) can't
    // merge events that arrive during that window. Buffer them here instead
    // of dropping them, then fold them into the fetched list once it's
    // ready — after that, later events go through `_onOrderCreated` as
    // normal.
    //
    // Keyed by order id, not a plain list: the socket can deliver two events
    // for the same brand-new order inside the fetch window (a redelivery, or
    // a create followed by an immediate update), and the merge below only
    // dedups the buffer against the *fetched* list — so without this a
    // same-id pair would both survive and render as duplicate rows.
    final pendingDuringFetch = <String, TenantOrder>{};
    // Buffering is strictly a fetch-window measure. `build()` can also
    // *fail* (no branch id, `fetchOrders` throws), leaving `state.value`
    // null forever — and an unbounded buffer growing on every incoming
    // event for the rest of the session with it. Flipping this the moment
    // the fetch settles (resolved OR threw) bounds the buffer to that
    // window; events after a failed build are dropped by `_onOrderCreated`,
    // which is correct — there is no list to merge them into, and the next
    // successful build refetches from scratch.
    var initialFetchSettled = false;
    _orderCreatedSubscription = realtime.orderCreated.listen((payload) {
      if (state.value == null && !initialFetchSettled) {
        final order = TenantOrder.fromBroadcastPayload(payload);
        pendingDuringFetch[order.id] = order;
      } else {
        _onOrderCreated(payload);
      }
    });
    _reconnectedSubscription =
        realtime.reconnected.listen((_) => _onReconnected(repository));

    final List<TenantOrder> orders;
    try {
      orders = await repository.fetchOrders(branchId: branchId);
    } finally {
      initialFetchSettled = true;
    }
    _trackBroadcastEventId(orders);
    final fetched = _excludeCancelled(orders);
    if (pendingDuringFetch.isEmpty) return fetched;

    final buffered = pendingDuringFetch.values.toList();
    _trackBroadcastEventId(buffered);
    final fetchedIds = fetched.map((o) => o.id).toSet();
    final fresh =
        _excludeCancelled(buffered).where((o) => !fetchedIds.contains(o.id));
    return [...fresh, ...fetched];
  }

  void _onOrderCreated(Map<String, dynamic> payload) {
    final order = TenantOrder.fromBroadcastPayload(payload);
    final current = state.value;
    if (current == null) return;
    if (current.any((o) => o.id == order.id)) return;
    _trackBroadcastEventId([order]);
    state = AsyncData([order, ...current]);
  }

  Future<void> _onReconnected(TenantOrderRepository repository) async {
    final afterId = _lastBroadcastEventId;
    if (afterId == null) return;
    // This runs from a stream listener (`realtime.reconnected.listen`), so
    // nothing is awaiting its future — an escaping exception would surface as
    // an uncaught async error (and in tests, fail an unrelated test) rather
    // than as anything the user could act on. A failed gap-fill is also not
    // fatal: the board's current list is still valid, just possibly missing
    // orders created while the socket was down, and the next reconnect
    // retries with the same `afterId`. So swallow it and leave `state`
    // untouched.
    final List<TenantOrder> missed;
    try {
      missed = await repository.fetchMissedEvents(
        branchId: _branchId,
        afterId: afterId,
      );
    } on Object catch (error) {
      // Same best-effort pattern as `dioProvider`'s realtime disconnect and
      // `AuthController.logout`: log for diagnosis, never propagate.
      debugPrint('TenantOrderBoard gap-fill failed, keeping current list: '
          '$error');
      return;
    }
    final current = state.value;
    if (current == null || missed.isEmpty) return;
    final currentIds = current.map((o) => o.id).toSet();
    final fresh = missed.where((o) => !currentIds.contains(o.id));
    _trackBroadcastEventId(missed);
    state = AsyncData([...fresh, ...current]);
  }

  void _trackBroadcastEventId(List<TenantOrder> orders) {
    for (final order in orders) {
      final id = order.broadcastEventId;
      if (id != null &&
          (_lastBroadcastEventId == null || id > _lastBroadcastEventId!)) {
        _lastBroadcastEventId = id;
      }
    }
  }

  List<TenantOrder> _excludeCancelled(List<TenantOrder> orders) =>
      orders.where((o) => o.status != TenantOrderStatus.cancelled).toList();

  /// Accepts every item — a thin wrapper over [_process] with nothing
  /// rejected.
  Future<void> accept(String orderId) =>
      _process(orderId, rejectedItemIds: const []);

  /// Sends the tenant's per-item decision for a PENDING order. The backend
  /// derives the result: [rejectedItemIds] empty is a no-op for this method
  /// (use [accept]); some or all of the order's items rejected moves it to
  /// PREPARING (partial) or CANCELLED (all) — see [_process].
  Future<void> reject(
    String orderId, {
    required List<String> rejectedItemIds,
  }) =>
      _process(orderId, rejectedItemIds: rejectedItemIds);

  /// `POST /v1/orders/{id}/process` — the PENDING-only accept/reject
  /// decision. Guards + optimistic-update-then-rollback mirror [_transition];
  /// the one extra piece of logic is deriving whether every item was
  /// rejected (→ remove the now-cancelled order from the board, same as
  /// `_transition`'s old cancelled case) or not (→ PREPARING, in place).
  Future<void> _process(
    String orderId, {
    required List<String> rejectedItemIds,
  }) async {
    final current = state.value;
    if (current == null) {
      throw StateError(
        'TenantOrderBoard: cannot process order $orderId — the board has not '
        'finished loading',
      );
    }
    final index = current.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      throw StateError(
        'TenantOrderBoard: cannot process order $orderId — it is not on the '
        'board',
      );
    }
    final previous = current[index];
    final allRejected = previous.items.isNotEmpty &&
        previous.items.every((item) => rejectedItemIds.contains(item.id));

    // ponytail: the item list itself isn't pruned on a partial reject (stays
    // stale until the next fetch/realtime event) — upgrade if the Diproses
    // card needs to reflect exactly which items survived.
    final optimistic = allRejected
        ? [for (final o in current) if (o.id != orderId) o]
        : [
            for (final o in current)
              if (o.id == orderId)
                previous.copyWith(status: TenantOrderStatus.preparing)
              else
                o,
          ];
    state = AsyncData(optimistic);

    try {
      await ref.read(tenantOrderRepositoryProvider).processOrder(
            orderId,
            rejectedItemIds: rejectedItemIds,
          );
    } on Object catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> markReady(String orderId) =>
      _transition(orderId, TenantOrderStatus.ready);

  Future<void> _transition(String orderId, TenantOrderStatus target) async {
    // Both guards below used to `return` silently. That turned every
    // mis-targeted mutation into a fake success: the caller saw no
    // exception, showed its success feedback, and the backend was never
    // told — the order sat there unchanged. Neither case is a state a
    // correct caller can reach (screens only offer actions for orders they
    // are currently rendering off this board), so both are bugs that must
    // surface. Throwing routes them into the screens' existing
    // catch-and-SnackBar handling instead of silently lying to the tenant.
    final current = state.value;
    if (current == null) {
      throw StateError(
        'TenantOrderBoard: cannot move order $orderId to $target — the board '
        'has not finished loading',
      );
    }
    final index = current.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      throw StateError(
        'TenantOrderBoard: cannot move order $orderId to $target — it is not '
        'on the board',
      );
    }
    final previous = current[index];
    state = AsyncData([
      for (final o in current)
        if (o.id == orderId) previous.copyWith(status: target) else o,
    ]);

    try {
      await ref
          .read(tenantOrderRepositoryProvider)
          .updateStatus(orderId, status: target);
    } on Object catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

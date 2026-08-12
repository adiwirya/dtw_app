import 'dart:async';

import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:dtw_app/features/tenant/data/repositories/tenant_order_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tenant_order_provider.g.dart';

/// The tenant "Order" board: fetches once from the real API, then stays
/// live via `TenantRealtimeService.orderCreated` — no polling. [accept],
/// [reject] and [markReady] optimistically update local state, call the
/// repository, and revert-and-rethrow on failure so the screen can show an
/// error (see `TenantOrderScreen`).
///
/// Kept alive (not the `@riverpod` default autoDispose) because its
/// `build()` opens the realtime subscriptions that keep the board live —
/// those must not be torn down just because the screen briefly stops being
/// watched (e.g. a transient rebuild), only on session end/logout.
@Riverpod(keepAlive: true)
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

    _orderCreatedSubscription = realtime.orderCreated.listen(_onOrderCreated);
    _reconnectedSubscription =
        realtime.reconnected.listen((_) => _onReconnected(repository));

    final orders = await repository.fetchOrders(branchId: branchId);
    _trackBroadcastEventId(orders);
    return _excludeCancelled(orders);
  }

  void _onOrderCreated(Map<String, dynamic> payload) {
    final order = TenantOrder.fromJson(payload);
    final current = state.value;
    if (current == null) return;
    if (current.any((o) => o.id == order.id)) return;
    _trackBroadcastEventId([order]);
    state = AsyncData([order, ...current]);
  }

  Future<void> _onReconnected(TenantOrderRepository repository) async {
    final afterId = _lastBroadcastEventId;
    if (afterId == null) return;
    final missed = await repository.fetchMissedEvents(
      branchId: _branchId,
      afterId: afterId,
    );
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

  Future<void> accept(String orderId) =>
      _transition(orderId, TenantOrderStatus.preparing);

  Future<void> markReady(String orderId) =>
      _transition(orderId, TenantOrderStatus.ready);

  Future<void> reject(
    String orderId, {
    required String reason,
    List<String>? rejectedItemNames,
  }) =>
      // rejectedItemNames is UI-only for now (open follow-up: whether the
      // API supports partial-item rejection) — not sent to the backend.
      _transition(orderId, TenantOrderStatus.cancelled, reason: reason);

  Future<void> _transition(
    String orderId,
    TenantOrderStatus target, {
    String? reason,
  }) async {
    final current = state.value;
    if (current == null) return;
    final index = current.indexWhere((o) => o.id == orderId);
    if (index == -1) return;
    final previous = current[index];

    // A cancelled order is excluded from the board entirely (see
    // `incomingOrderStatusFromBackend`, which deliberately throws for
    // `cancelled` — it must never reach the mapper), so "reject" removes
    // the row instead of updating it in place like accept/markReady do.
    final optimistic = target == TenantOrderStatus.cancelled
        ? [for (final o in current) if (o.id != orderId) o]
        : [
            for (final o in current)
              if (o.id == orderId) previous.copyWith(status: target) else o,
          ];
    state = AsyncData(optimistic);

    try {
      await ref.read(tenantOrderRepositoryProvider).updateStatus(
            orderId,
            status: target,
            reason: reason,
          );
    } catch (error) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

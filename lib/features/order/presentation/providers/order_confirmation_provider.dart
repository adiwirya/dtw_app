import 'dart:async';

import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/realtime/busboy_realtime_service.dart';
import 'package:dtw_app/features/order/data/models/order_confirmation.dart';
import 'package:dtw_app/features/order/data/repositories/busboy_confirmation_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'order_confirmation_provider.g.dart';

/// The busboy's "customer must decide" tasks, fetched from
/// `GET /v1/busboy/order-confirmations` and kept live via the
/// `order-confirmation.created/claimed/resolved` events on
/// `private-zone.<zoneId>`.
///
/// The list holds every row the server returns (including resolved ones and
/// other busboys' claims); [openConfirmationsProvider] is the filtered view
/// the Order tab and detail screen show.
@riverpod
class OrderConfirmationBoard extends _$OrderConfirmationBoard {
  @override
  Future<List<OrderConfirmation>> build() async {
    final realtime = ref.watch(busboyRealtimeServiceProvider);

    // Events missed while the socket was down are gone (no busboy replay
    // endpoint): refetch to gap-fill, keeping the old list visible meanwhile.
    final subscriptions = [
      realtime.reconnected.listen((_) => ref.invalidateSelf()),
      for (final stream in [
        realtime.confirmationCreated,
        realtime.confirmationClaimed,
        realtime.confirmationResolved,
      ])
        stream.listen(
          (payload) => _upsert(OrderConfirmation.fromJson(payload)),
        ),
    ];
    ref.onDispose(() {
      for (final subscription in subscriptions) {
        unawaited(subscription.cancel());
      }
    });

    return ref.watch(busboyConfirmationRepositoryProvider).fetchConfirmations();
  }

  // ponytail: an event that lands before the first fetch settles is dropped
  // (the fetch result already reflects it); add buffering like
  // OrderBoardNotifier if a created-event ever races the initial load.
  void _upsert(OrderConfirmation confirmation) {
    final current = state.value;
    if (current == null) return;
    final exists = current.any((c) => c.id == confirmation.id);
    state = AsyncData([
      if (!exists) confirmation,
      for (final c in current) if (c.id == confirmation.id) confirmation else c,
    ]);
  }

  /// Records the customer's [decision]: claims the task first when this
  /// busboy has not already (the design has a single decision step, no
  /// separate "take" button), then resolves it. A 409 from the claim means
  /// another busboy was faster and propagates to the caller.
  Future<void> decide(
    OrderConfirmation confirmation,
    ConfirmationDecision decision,
  ) async {
    final repository = ref.read(busboyConfirmationRepositoryProvider);
    final myUserId = ref.read(sessionUserIdProvider);
    if (confirmation.busboyUserId != myUserId) {
      _upsert(await repository.claim(confirmation.id));
    }
    _upsert(await repository.resolve(confirmation.id, decision));
  }
}

/// The confirmations this busboy can still act on: unresolved, and either
/// free or already claimed by this busboy. Empty while loading or on error —
/// a failing confirmations endpoint must not break the delivery board.
@riverpod
List<OrderConfirmation> openConfirmations(Ref ref) {
  final all = ref.watch(orderConfirmationBoardProvider).value;
  final myUserId = ref.watch(sessionUserIdProvider);
  if (all == null) return const [];
  return [
    for (final c in all)
      if (c.isOpenFor(myUserId)) c,
  ];
}

/// One open confirmation by id, or null when it is gone (resolved, taken by
/// another busboy) or the board has not loaded.
@riverpod
OrderConfirmation? confirmationById(Ref ref, String id) {
  for (final c in ref.watch(openConfirmationsProvider)) {
    if (c.id == id) return c;
  }
  return null;
}

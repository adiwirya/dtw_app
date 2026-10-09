// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_order_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(TenantOrderBoard)
final tenantOrderBoardProvider = TenantOrderBoardProvider._();

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
final class TenantOrderBoardProvider
    extends $AsyncNotifierProvider<TenantOrderBoard, List<TenantOrder>> {
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
  TenantOrderBoardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tenantOrderBoardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tenantOrderBoardHash();

  @$internal
  @override
  TenantOrderBoard create() => TenantOrderBoard();
}

String _$tenantOrderBoardHash() => r'bbe7d21b58113b8379178a4d8cdecb27e5ae02bd';

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

abstract class _$TenantOrderBoard extends $AsyncNotifier<List<TenantOrder>> {
  FutureOr<List<TenantOrder>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<TenantOrder>>, List<TenantOrder>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<TenantOrder>>, List<TenantOrder>>,
              AsyncValue<List<TenantOrder>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

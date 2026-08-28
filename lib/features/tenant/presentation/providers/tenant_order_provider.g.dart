// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_order_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tenantOrderBoardHash() => r'11d88fe81f9fdbe0f68f233078f1ff59f2e09ee7';

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
///
/// Copied from [TenantOrderBoard].
@ProviderFor(TenantOrderBoard)
final tenantOrderBoardProvider =
    AutoDisposeAsyncNotifierProvider<
      TenantOrderBoard,
      List<TenantOrder>
    >.internal(
      TenantOrderBoard.new,
      name: r'tenantOrderBoardProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$tenantOrderBoardHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TenantOrderBoard = AutoDisposeAsyncNotifier<List<TenantOrder>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

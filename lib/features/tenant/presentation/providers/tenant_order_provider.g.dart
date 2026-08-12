// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_order_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tenantOrderBoardHash() => r'0a820c180d21a7e7eaa256b1edc1ff77c2dddd2a';

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
///
/// Copied from [TenantOrderBoard].
@ProviderFor(TenantOrderBoard)
final tenantOrderBoardProvider =
    AsyncNotifierProvider<TenantOrderBoard, List<TenantOrder>>.internal(
      TenantOrderBoard.new,
      name: r'tenantOrderBoardProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$tenantOrderBoardHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TenantOrderBoard = AsyncNotifier<List<TenantOrder>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

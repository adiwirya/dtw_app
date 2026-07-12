// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_order_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tenantOrderBoardHash() => r'bc2611862fed32a13957dfc1e8f08f72b04373e4';

/// The mock tenant "Order" board: a flat list of [IncomingOrderData] spanning
/// the three sub-tabs (`baru` / `diproses` / `selesai`). The screen filters by
/// [IncomingOrderData.status] to render each sub-tab in place.
///
/// A class-based `@riverpod` notifier so mutations go through `state`
/// (per this work item's Riverpod constraint). [accept] and [markReady] are
/// UI-only mock transitions.
///
/// Copied from [TenantOrderBoard].
@ProviderFor(TenantOrderBoard)
final tenantOrderBoardProvider =
    AutoDisposeNotifierProvider<
      TenantOrderBoard,
      List<IncomingOrderData>
    >.internal(
      TenantOrderBoard.new,
      name: r'tenantOrderBoardProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$tenantOrderBoardHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TenantOrderBoard = AutoDisposeNotifier<List<IncomingOrderData>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

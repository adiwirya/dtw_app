// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$orderHeaderStatsHash() => r'65254db3161d8f16f4d7c963dd82b07a29d47989';

/// The three header summary stats on the Order home (`menu-order-baru`).
///
/// Copied from [orderHeaderStats].
@ProviderFor(orderHeaderStats)
final orderHeaderStatsProvider =
    AutoDisposeProvider<List<OrderHeaderStat>>.internal(
      orderHeaderStats,
      name: r'orderHeaderStatsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$orderHeaderStatsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OrderHeaderStatsRef = AutoDisposeProviderRef<List<OrderHeaderStat>>;
String _$orderDetailHash() => r'ba1c8be1515a2615ac5102c06ab7495bd0970ba3';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Looks [orderId] (a delivery id) up out of the same list
/// [orderBoardNotifierProvider] holds — null while the board is still
/// loading, has errored, or the delivery isn't (or is no longer) on it.
///
/// Copied from [orderDetail].
@ProviderFor(orderDetail)
const orderDetailProvider = OrderDetailFamily();

/// Looks [orderId] (a delivery id) up out of the same list
/// [orderBoardNotifierProvider] holds — null while the board is still
/// loading, has errored, or the delivery isn't (or is no longer) on it.
///
/// Copied from [orderDetail].
class OrderDetailFamily extends Family<OrderDetail?> {
  /// Looks [orderId] (a delivery id) up out of the same list
  /// [orderBoardNotifierProvider] holds — null while the board is still
  /// loading, has errored, or the delivery isn't (or is no longer) on it.
  ///
  /// Copied from [orderDetail].
  const OrderDetailFamily();

  /// Looks [orderId] (a delivery id) up out of the same list
  /// [orderBoardNotifierProvider] holds — null while the board is still
  /// loading, has errored, or the delivery isn't (or is no longer) on it.
  ///
  /// Copied from [orderDetail].
  OrderDetailProvider call(String orderId) {
    return OrderDetailProvider(orderId);
  }

  @override
  OrderDetailProvider getProviderOverride(
    covariant OrderDetailProvider provider,
  ) {
    return call(provider.orderId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'orderDetailProvider';
}

/// Looks [orderId] (a delivery id) up out of the same list
/// [orderBoardNotifierProvider] holds — null while the board is still
/// loading, has errored, or the delivery isn't (or is no longer) on it.
///
/// Copied from [orderDetail].
class OrderDetailProvider extends AutoDisposeProvider<OrderDetail?> {
  /// Looks [orderId] (a delivery id) up out of the same list
  /// [orderBoardNotifierProvider] holds — null while the board is still
  /// loading, has errored, or the delivery isn't (or is no longer) on it.
  ///
  /// Copied from [orderDetail].
  OrderDetailProvider(String orderId)
    : this._internal(
        (ref) => orderDetail(ref as OrderDetailRef, orderId),
        from: orderDetailProvider,
        name: r'orderDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$orderDetailHash,
        dependencies: OrderDetailFamily._dependencies,
        allTransitiveDependencies: OrderDetailFamily._allTransitiveDependencies,
        orderId: orderId,
      );

  OrderDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.orderId,
  }) : super.internal();

  final String orderId;

  @override
  Override overrideWith(OrderDetail? Function(OrderDetailRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: OrderDetailProvider._internal(
        (ref) => create(ref as OrderDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        orderId: orderId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<OrderDetail?> createElement() {
    return _OrderDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderDetailProvider && other.orderId == orderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, orderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin OrderDetailRef on AutoDisposeProviderRef<OrderDetail?> {
  /// The parameter `orderId` of this provider.
  String get orderId;
}

class _OrderDetailProviderElement
    extends AutoDisposeProviderElement<OrderDetail?>
    with OrderDetailRef {
  _OrderDetailProviderElement(super.provider);

  @override
  String get orderId => (origin as OrderDetailProvider).orderId;
}

String _$completedOrderDetailHash() =>
    r'd3422f5c74da06722b66a0b9483b81f77c0364c2';

/// Looks [orderId] up out of [orderBoardNotifierProvider] for the
/// `detail-selesai` (completed-order detail) page — null while the board is
/// still loading, has errored, or the delivery isn't on it.
///
/// Copied from [completedOrderDetail].
@ProviderFor(completedOrderDetail)
const completedOrderDetailProvider = CompletedOrderDetailFamily();

/// Looks [orderId] up out of [orderBoardNotifierProvider] for the
/// `detail-selesai` (completed-order detail) page — null while the board is
/// still loading, has errored, or the delivery isn't on it.
///
/// Copied from [completedOrderDetail].
class CompletedOrderDetailFamily extends Family<CompletedOrderDetail?> {
  /// Looks [orderId] up out of [orderBoardNotifierProvider] for the
  /// `detail-selesai` (completed-order detail) page — null while the board is
  /// still loading, has errored, or the delivery isn't on it.
  ///
  /// Copied from [completedOrderDetail].
  const CompletedOrderDetailFamily();

  /// Looks [orderId] up out of [orderBoardNotifierProvider] for the
  /// `detail-selesai` (completed-order detail) page — null while the board is
  /// still loading, has errored, or the delivery isn't on it.
  ///
  /// Copied from [completedOrderDetail].
  CompletedOrderDetailProvider call(String orderId) {
    return CompletedOrderDetailProvider(orderId);
  }

  @override
  CompletedOrderDetailProvider getProviderOverride(
    covariant CompletedOrderDetailProvider provider,
  ) {
    return call(provider.orderId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'completedOrderDetailProvider';
}

/// Looks [orderId] up out of [orderBoardNotifierProvider] for the
/// `detail-selesai` (completed-order detail) page — null while the board is
/// still loading, has errored, or the delivery isn't on it.
///
/// Copied from [completedOrderDetail].
class CompletedOrderDetailProvider
    extends AutoDisposeProvider<CompletedOrderDetail?> {
  /// Looks [orderId] up out of [orderBoardNotifierProvider] for the
  /// `detail-selesai` (completed-order detail) page — null while the board is
  /// still loading, has errored, or the delivery isn't on it.
  ///
  /// Copied from [completedOrderDetail].
  CompletedOrderDetailProvider(String orderId)
    : this._internal(
        (ref) => completedOrderDetail(ref as CompletedOrderDetailRef, orderId),
        from: completedOrderDetailProvider,
        name: r'completedOrderDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$completedOrderDetailHash,
        dependencies: CompletedOrderDetailFamily._dependencies,
        allTransitiveDependencies:
            CompletedOrderDetailFamily._allTransitiveDependencies,
        orderId: orderId,
      );

  CompletedOrderDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.orderId,
  }) : super.internal();

  final String orderId;

  @override
  Override overrideWith(
    CompletedOrderDetail? Function(CompletedOrderDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CompletedOrderDetailProvider._internal(
        (ref) => create(ref as CompletedOrderDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        orderId: orderId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<CompletedOrderDetail?> createElement() {
    return _CompletedOrderDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CompletedOrderDetailProvider && other.orderId == orderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, orderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CompletedOrderDetailRef on AutoDisposeProviderRef<CompletedOrderDetail?> {
  /// The parameter `orderId` of this provider.
  String get orderId;
}

class _CompletedOrderDetailProviderElement
    extends AutoDisposeProviderElement<CompletedOrderDetail?>
    with CompletedOrderDetailRef {
  _CompletedOrderDetailProviderElement(super.provider);

  @override
  String get orderId => (origin as CompletedOrderDetailProvider).orderId;
}

String _$orderTabHash() => r'e1c76da6748a4f81085bd1a5c7e7b88675773f57';

/// Currently selected Order sub-tab, as an index into
/// `[baru, antar, selesai]`. Kept as app state (not screen-local) so route
/// deep-links (`/order/antar`, `/order/selesai`) and the success-modal
/// `onConfirm` can switch the in-place tab.
///
/// Copied from [OrderTab].
@ProviderFor(OrderTab)
final orderTabProvider = AutoDisposeNotifierProvider<OrderTab, int>.internal(
  OrderTab.new,
  name: r'orderTabProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$orderTabHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$OrderTab = AutoDisposeNotifier<int>;
String _$orderBoardNotifierHash() =>
    r'c83e38a6da04a10a0285b6ae2c5f1f9b8ba604d3';

/// The busboy's raw delivery list, fetched once from
/// `GET /api/v1/busboy/deliveries` and kept live via
/// `BusboyRealtimeService.deliveryCreated` (`private-zone.<zoneId>`,
/// `delivery.created`) — no polling. The Order screen's three sub-tabs are
/// [orderBoardFrom] projections of this same list, and [orderDetailProvider]
/// looks a single delivery up out of it, so `claim`/`deliver` only need to
/// mutate this one list for every dependent view to update together.
///
/// Copied from [OrderBoardNotifier].
@ProviderFor(OrderBoardNotifier)
final orderBoardNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      OrderBoardNotifier,
      List<Delivery>
    >.internal(
      OrderBoardNotifier.new,
      name: r'orderBoardNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$orderBoardNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OrderBoardNotifier = AutoDisposeAsyncNotifier<List<Delivery>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

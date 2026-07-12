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
String _$orderDetailHash() => r'd0f2663f8488a7c0dc4f49bd96aec9314e04dca4';

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

/// Mock order detail for the `menu-order-baru-2` screen. Parameterised by order
/// id; only the single harvested mock (`92842`) exists for now.
///
/// Copied from [orderDetail].
@ProviderFor(orderDetail)
const orderDetailProvider = OrderDetailFamily();

/// Mock order detail for the `menu-order-baru-2` screen. Parameterised by order
/// id; only the single harvested mock (`92842`) exists for now.
///
/// Copied from [orderDetail].
class OrderDetailFamily extends Family<OrderDetail> {
  /// Mock order detail for the `menu-order-baru-2` screen. Parameterised by order
  /// id; only the single harvested mock (`92842`) exists for now.
  ///
  /// Copied from [orderDetail].
  const OrderDetailFamily();

  /// Mock order detail for the `menu-order-baru-2` screen. Parameterised by order
  /// id; only the single harvested mock (`92842`) exists for now.
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

/// Mock order detail for the `menu-order-baru-2` screen. Parameterised by order
/// id; only the single harvested mock (`92842`) exists for now.
///
/// Copied from [orderDetail].
class OrderDetailProvider extends AutoDisposeProvider<OrderDetail> {
  /// Mock order detail for the `menu-order-baru-2` screen. Parameterised by order
  /// id; only the single harvested mock (`92842`) exists for now.
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
  Override overrideWith(OrderDetail Function(OrderDetailRef provider) create) {
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
  AutoDisposeProviderElement<OrderDetail> createElement() {
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
mixin OrderDetailRef on AutoDisposeProviderRef<OrderDetail> {
  /// The parameter `orderId` of this provider.
  String get orderId;
}

class _OrderDetailProviderElement
    extends AutoDisposeProviderElement<OrderDetail>
    with OrderDetailRef {
  _OrderDetailProviderElement(super.provider);

  @override
  String get orderId => (origin as OrderDetailProvider).orderId;
}

String _$completedOrderDetailHash() =>
    r'f8e6160c25e70a98d8615511df63d157aafc4374';

/// Mock detail for the `detail-selesai` (completed-order detail) page. The
/// frame is identical to `detail-riwayat` except the `Informasi Pesanan`
/// "Tenan" value, which here shows the tenant name (`KFC Fried Chicken`).
///
/// Copied from [completedOrderDetail].
@ProviderFor(completedOrderDetail)
final completedOrderDetailProvider =
    AutoDisposeProvider<CompletedOrderDetail>.internal(
      completedOrderDetail,
      name: r'completedOrderDetailProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$completedOrderDetailHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CompletedOrderDetailRef = AutoDisposeProviderRef<CompletedOrderDetail>;
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
    r'd7db957b022400be6f686c2d9ffeb97003362407';

/// The mock Menu Order board, with UI-only Baru → Antar → Selesai transitions.
///
/// Copied from [OrderBoardNotifier].
@ProviderFor(OrderBoardNotifier)
final orderBoardNotifierProvider =
    AutoDisposeNotifierProvider<OrderBoardNotifier, OrderBoard>.internal(
      OrderBoardNotifier.new,
      name: r'orderBoardNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$orderBoardNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OrderBoardNotifier = AutoDisposeNotifier<OrderBoard>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

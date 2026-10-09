// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The three header summary stats on the Order home (`menu-order-baru`).
/// Only "Pesanan Selesai" has real backing data (today's delivered count off
/// the same board this screen already renders) — the busboy API has no
/// on-time-rate or customer-rating endpoint, so those two stay `-` rather
/// than a fabricated number.

@ProviderFor(orderHeaderStats)
final orderHeaderStatsProvider = OrderHeaderStatsProvider._();

/// The three header summary stats on the Order home (`menu-order-baru`).
/// Only "Pesanan Selesai" has real backing data (today's delivered count off
/// the same board this screen already renders) — the busboy API has no
/// on-time-rate or customer-rating endpoint, so those two stay `-` rather
/// than a fabricated number.

final class OrderHeaderStatsProvider
    extends
        $FunctionalProvider<
          List<OrderHeaderStat>,
          List<OrderHeaderStat>,
          List<OrderHeaderStat>
        >
    with $Provider<List<OrderHeaderStat>> {
  /// The three header summary stats on the Order home (`menu-order-baru`).
  /// Only "Pesanan Selesai" has real backing data (today's delivered count off
  /// the same board this screen already renders) — the busboy API has no
  /// on-time-rate or customer-rating endpoint, so those two stay `-` rather
  /// than a fabricated number.
  OrderHeaderStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orderHeaderStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orderHeaderStatsHash();

  @$internal
  @override
  $ProviderElement<List<OrderHeaderStat>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<OrderHeaderStat> create(Ref ref) {
    return orderHeaderStats(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<OrderHeaderStat> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<OrderHeaderStat>>(value),
    );
  }
}

String _$orderHeaderStatsHash() => r'689f669f774ba18e3ccb3cde43859f2ffde10280';

/// Currently selected Order sub-tab, as an index into
/// `[baru, antar, selesai]`. Kept as app state (not screen-local) so route
/// deep-links (`/order/antar`, `/order/selesai`) and the success-modal
/// `onConfirm` can switch the in-place tab.

@ProviderFor(OrderTab)
final orderTabProvider = OrderTabProvider._();

/// Currently selected Order sub-tab, as an index into
/// `[baru, antar, selesai]`. Kept as app state (not screen-local) so route
/// deep-links (`/order/antar`, `/order/selesai`) and the success-modal
/// `onConfirm` can switch the in-place tab.
final class OrderTabProvider extends $NotifierProvider<OrderTab, int> {
  /// Currently selected Order sub-tab, as an index into
  /// `[baru, antar, selesai]`. Kept as app state (not screen-local) so route
  /// deep-links (`/order/antar`, `/order/selesai`) and the success-modal
  /// `onConfirm` can switch the in-place tab.
  OrderTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orderTabProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orderTabHash();

  @$internal
  @override
  OrderTab create() => OrderTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$orderTabHash() => r'e1c76da6748a4f81085bd1a5c7e7b88675773f57';

/// Currently selected Order sub-tab, as an index into
/// `[baru, antar, selesai]`. Kept as app state (not screen-local) so route
/// deep-links (`/order/antar`, `/order/selesai`) and the success-modal
/// `onConfirm` can switch the in-place tab.

abstract class _$OrderTab extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The busboy's raw delivery list, fetched once from
/// `GET /v1/busboy/deliveries` and kept live via
/// `BusboyRealtimeService`'s `delivery.created`/`delivery.claimed`/
/// `delivery.completed` (`private-zone.<zoneId>`) — no polling. The Order
/// screen's three sub-tabs are [orderBoardFrom] projections of this same
/// list, and [orderDetailProvider] looks a single delivery up out of it, so
/// `claim`/`deliver` only need to mutate this one list for every dependent
/// view to update together.

@ProviderFor(OrderBoardNotifier)
final orderBoardProvider = OrderBoardNotifierProvider._();

/// The busboy's raw delivery list, fetched once from
/// `GET /v1/busboy/deliveries` and kept live via
/// `BusboyRealtimeService`'s `delivery.created`/`delivery.claimed`/
/// `delivery.completed` (`private-zone.<zoneId>`) — no polling. The Order
/// screen's three sub-tabs are [orderBoardFrom] projections of this same
/// list, and [orderDetailProvider] looks a single delivery up out of it, so
/// `claim`/`deliver` only need to mutate this one list for every dependent
/// view to update together.
final class OrderBoardNotifierProvider
    extends $AsyncNotifierProvider<OrderBoardNotifier, List<Delivery>> {
  /// The busboy's raw delivery list, fetched once from
  /// `GET /v1/busboy/deliveries` and kept live via
  /// `BusboyRealtimeService`'s `delivery.created`/`delivery.claimed`/
  /// `delivery.completed` (`private-zone.<zoneId>`) — no polling. The Order
  /// screen's three sub-tabs are [orderBoardFrom] projections of this same
  /// list, and [orderDetailProvider] looks a single delivery up out of it, so
  /// `claim`/`deliver` only need to mutate this one list for every dependent
  /// view to update together.
  OrderBoardNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orderBoardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orderBoardNotifierHash();

  @$internal
  @override
  OrderBoardNotifier create() => OrderBoardNotifier();
}

String _$orderBoardNotifierHash() =>
    r'131011fc215665a1d57dc51ae7a0ffa2e71f16c5';

/// The busboy's raw delivery list, fetched once from
/// `GET /v1/busboy/deliveries` and kept live via
/// `BusboyRealtimeService`'s `delivery.created`/`delivery.claimed`/
/// `delivery.completed` (`private-zone.<zoneId>`) — no polling. The Order
/// screen's three sub-tabs are [orderBoardFrom] projections of this same
/// list, and [orderDetailProvider] looks a single delivery up out of it, so
/// `claim`/`deliver` only need to mutate this one list for every dependent
/// view to update together.

abstract class _$OrderBoardNotifier extends $AsyncNotifier<List<Delivery>> {
  FutureOr<List<Delivery>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Delivery>>, List<Delivery>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Delivery>>, List<Delivery>>,
              AsyncValue<List<Delivery>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Looks [orderId] (a delivery id) up out of the same list
/// [orderBoardProvider] holds — null while the board is still
/// loading, has errored, or the delivery isn't (or is no longer) on it.

@ProviderFor(orderDetail)
final orderDetailProvider = OrderDetailFamily._();

/// Looks [orderId] (a delivery id) up out of the same list
/// [orderBoardProvider] holds — null while the board is still
/// loading, has errored, or the delivery isn't (or is no longer) on it.

final class OrderDetailProvider
    extends $FunctionalProvider<OrderDetail?, OrderDetail?, OrderDetail?>
    with $Provider<OrderDetail?> {
  /// Looks [orderId] (a delivery id) up out of the same list
  /// [orderBoardProvider] holds — null while the board is still
  /// loading, has errored, or the delivery isn't (or is no longer) on it.
  OrderDetailProvider._({
    required OrderDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderDetailHash();

  @override
  String toString() {
    return r'orderDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<OrderDetail?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OrderDetail? create(Ref ref) {
    final argument = this.argument as String;
    return orderDetail(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrderDetail? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrderDetail?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OrderDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderDetailHash() => r'10714b9b5b47c4feddfdc0937102266dea311656';

/// Looks [orderId] (a delivery id) up out of the same list
/// [orderBoardProvider] holds — null while the board is still
/// loading, has errored, or the delivery isn't (or is no longer) on it.

final class OrderDetailFamily extends $Family
    with $FunctionalFamilyOverride<OrderDetail?, String> {
  OrderDetailFamily._()
    : super(
        retry: null,
        name: r'orderDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Looks [orderId] (a delivery id) up out of the same list
  /// [orderBoardProvider] holds — null while the board is still
  /// loading, has errored, or the delivery isn't (or is no longer) on it.

  OrderDetailProvider call(String orderId) =>
      OrderDetailProvider._(argument: orderId, from: this);

  @override
  String toString() => r'orderDetailProvider';
}

/// Looks [orderId] up out of [orderBoardProvider] for the
/// `detail-selesai` (completed-order detail) page — null while the board is
/// still loading, has errored, or the delivery isn't on it.

@ProviderFor(completedOrderDetail)
final completedOrderDetailProvider = CompletedOrderDetailFamily._();

/// Looks [orderId] up out of [orderBoardProvider] for the
/// `detail-selesai` (completed-order detail) page — null while the board is
/// still loading, has errored, or the delivery isn't on it.

final class CompletedOrderDetailProvider
    extends
        $FunctionalProvider<
          CompletedOrderDetail?,
          CompletedOrderDetail?,
          CompletedOrderDetail?
        >
    with $Provider<CompletedOrderDetail?> {
  /// Looks [orderId] up out of [orderBoardProvider] for the
  /// `detail-selesai` (completed-order detail) page — null while the board is
  /// still loading, has errored, or the delivery isn't on it.
  CompletedOrderDetailProvider._({
    required CompletedOrderDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'completedOrderDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$completedOrderDetailHash();

  @override
  String toString() {
    return r'completedOrderDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<CompletedOrderDetail?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CompletedOrderDetail? create(Ref ref) {
    final argument = this.argument as String;
    return completedOrderDetail(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CompletedOrderDetail? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CompletedOrderDetail?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CompletedOrderDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$completedOrderDetailHash() =>
    r'6f945528e30842d60374b4bf4b8266e7607af500';

/// Looks [orderId] up out of [orderBoardProvider] for the
/// `detail-selesai` (completed-order detail) page — null while the board is
/// still loading, has errored, or the delivery isn't on it.

final class CompletedOrderDetailFamily extends $Family
    with $FunctionalFamilyOverride<CompletedOrderDetail?, String> {
  CompletedOrderDetailFamily._()
    : super(
        retry: null,
        name: r'completedOrderDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Looks [orderId] up out of [orderBoardProvider] for the
  /// `detail-selesai` (completed-order detail) page — null while the board is
  /// still loading, has errored, or the delivery isn't on it.

  CompletedOrderDetailProvider call(String orderId) =>
      CompletedOrderDetailProvider._(argument: orderId, from: this);

  @override
  String toString() => r'completedOrderDetailProvider';
}

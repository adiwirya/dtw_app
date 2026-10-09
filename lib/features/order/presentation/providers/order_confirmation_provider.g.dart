// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_confirmation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The busboy's "customer must decide" tasks, fetched from
/// `GET /v1/busboy/order-confirmations` and kept live via the
/// `order-confirmation.created/claimed/resolved` events on
/// `private-zone.<zoneId>`.
///
/// The list holds every row the server returns (including resolved ones and
/// other busboys' claims); [openConfirmationsProvider] is the filtered view
/// the Order tab and detail screen show.

@ProviderFor(OrderConfirmationBoard)
final orderConfirmationBoardProvider = OrderConfirmationBoardProvider._();

/// The busboy's "customer must decide" tasks, fetched from
/// `GET /v1/busboy/order-confirmations` and kept live via the
/// `order-confirmation.created/claimed/resolved` events on
/// `private-zone.<zoneId>`.
///
/// The list holds every row the server returns (including resolved ones and
/// other busboys' claims); [openConfirmationsProvider] is the filtered view
/// the Order tab and detail screen show.
final class OrderConfirmationBoardProvider
    extends
        $AsyncNotifierProvider<
          OrderConfirmationBoard,
          List<OrderConfirmation>
        > {
  /// The busboy's "customer must decide" tasks, fetched from
  /// `GET /v1/busboy/order-confirmations` and kept live via the
  /// `order-confirmation.created/claimed/resolved` events on
  /// `private-zone.<zoneId>`.
  ///
  /// The list holds every row the server returns (including resolved ones and
  /// other busboys' claims); [openConfirmationsProvider] is the filtered view
  /// the Order tab and detail screen show.
  OrderConfirmationBoardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orderConfirmationBoardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orderConfirmationBoardHash();

  @$internal
  @override
  OrderConfirmationBoard create() => OrderConfirmationBoard();
}

String _$orderConfirmationBoardHash() =>
    r'0d6b8b15559a1c54c8908b03ce20987bf2ed649b';

/// The busboy's "customer must decide" tasks, fetched from
/// `GET /v1/busboy/order-confirmations` and kept live via the
/// `order-confirmation.created/claimed/resolved` events on
/// `private-zone.<zoneId>`.
///
/// The list holds every row the server returns (including resolved ones and
/// other busboys' claims); [openConfirmationsProvider] is the filtered view
/// the Order tab and detail screen show.

abstract class _$OrderConfirmationBoard
    extends $AsyncNotifier<List<OrderConfirmation>> {
  FutureOr<List<OrderConfirmation>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<OrderConfirmation>>,
              List<OrderConfirmation>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<OrderConfirmation>>,
                List<OrderConfirmation>
              >,
              AsyncValue<List<OrderConfirmation>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The confirmations this busboy can still act on: unresolved, and either
/// free or already claimed by this busboy. Empty while loading or on error —
/// a failing confirmations endpoint must not break the delivery board.

@ProviderFor(openConfirmations)
final openConfirmationsProvider = OpenConfirmationsProvider._();

/// The confirmations this busboy can still act on: unresolved, and either
/// free or already claimed by this busboy. Empty while loading or on error —
/// a failing confirmations endpoint must not break the delivery board.

final class OpenConfirmationsProvider
    extends
        $FunctionalProvider<
          List<OrderConfirmation>,
          List<OrderConfirmation>,
          List<OrderConfirmation>
        >
    with $Provider<List<OrderConfirmation>> {
  /// The confirmations this busboy can still act on: unresolved, and either
  /// free or already claimed by this busboy. Empty while loading or on error —
  /// a failing confirmations endpoint must not break the delivery board.
  OpenConfirmationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openConfirmationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openConfirmationsHash();

  @$internal
  @override
  $ProviderElement<List<OrderConfirmation>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<OrderConfirmation> create(Ref ref) {
    return openConfirmations(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<OrderConfirmation> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<OrderConfirmation>>(value),
    );
  }
}

String _$openConfirmationsHash() => r'cf67d85dea17ea2776518e6a6bc644e22d6bb322';

/// One open confirmation by id, or null when it is gone (resolved, taken by
/// another busboy) or the board has not loaded.

@ProviderFor(confirmationById)
final confirmationByIdProvider = ConfirmationByIdFamily._();

/// One open confirmation by id, or null when it is gone (resolved, taken by
/// another busboy) or the board has not loaded.

final class ConfirmationByIdProvider
    extends
        $FunctionalProvider<
          OrderConfirmation?,
          OrderConfirmation?,
          OrderConfirmation?
        >
    with $Provider<OrderConfirmation?> {
  /// One open confirmation by id, or null when it is gone (resolved, taken by
  /// another busboy) or the board has not loaded.
  ConfirmationByIdProvider._({
    required ConfirmationByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'confirmationByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$confirmationByIdHash();

  @override
  String toString() {
    return r'confirmationByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<OrderConfirmation?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OrderConfirmation? create(Ref ref) {
    final argument = this.argument as String;
    return confirmationById(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrderConfirmation? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrderConfirmation?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConfirmationByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$confirmationByIdHash() => r'94d5ef6bbf8bf8edbe2cf416f2dac81da7006155';

/// One open confirmation by id, or null when it is gone (resolved, taken by
/// another busboy) or the board has not loaded.

final class ConfirmationByIdFamily extends $Family
    with $FunctionalFamilyOverride<OrderConfirmation?, String> {
  ConfirmationByIdFamily._()
    : super(
        retry: null,
        name: r'confirmationByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One open confirmation by id, or null when it is gone (resolved, taken by
  /// another busboy) or the board has not loaded.

  ConfirmationByIdProvider call(String id) =>
      ConfirmationByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'confirmationByIdProvider';
}

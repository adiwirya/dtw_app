// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_order_alerts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(newOrderAlerts)
final newOrderAlertsProvider = NewOrderAlertsProvider._();

final class NewOrderAlertsProvider
    extends $FunctionalProvider<NewOrderAlerts, NewOrderAlerts, NewOrderAlerts>
    with $Provider<NewOrderAlerts> {
  NewOrderAlertsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newOrderAlertsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newOrderAlertsHash();

  @$internal
  @override
  $ProviderElement<NewOrderAlerts> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NewOrderAlerts create(Ref ref) {
    return newOrderAlerts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NewOrderAlerts value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NewOrderAlerts>(value),
    );
  }
}

String _$newOrderAlertsHash() => r'033e4ecb8fd6c03b3797a2ba8e8f3a6f79be0962';

@ProviderFor(busboyNewOrderAlerts)
final busboyNewOrderAlertsProvider = BusboyNewOrderAlertsProvider._();

final class BusboyNewOrderAlertsProvider
    extends $FunctionalProvider<NewOrderAlerts, NewOrderAlerts, NewOrderAlerts>
    with $Provider<NewOrderAlerts> {
  BusboyNewOrderAlertsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'busboyNewOrderAlertsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$busboyNewOrderAlertsHash();

  @$internal
  @override
  $ProviderElement<NewOrderAlerts> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NewOrderAlerts create(Ref ref) {
    return busboyNewOrderAlerts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NewOrderAlerts value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NewOrderAlerts>(value),
    );
  }
}

String _$busboyNewOrderAlertsHash() =>
    r'33570edff39d0133b3dc604aee4f9269959c59f5';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_delivery_alert_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Chimes/notifies a busboy session when a new delivery lands
/// (`delivery.created` on `private-zone.<zoneId>`) — the busboy-side mirror
/// of `NewOrderAlertBanner`.
///
/// No in-app banner like the tenant side: a new delivery already appears
/// immediately at the top of the Order home's Baru sub-tab
/// (`OrderBoardNotifier._onDeliveryCreated`), so there is nothing this needs
/// to show — only the audio/tray-notification side effect.

@ProviderFor(NewDeliveryAlert)
final newDeliveryAlertProvider = NewDeliveryAlertProvider._();

/// Chimes/notifies a busboy session when a new delivery lands
/// (`delivery.created` on `private-zone.<zoneId>`) — the busboy-side mirror
/// of `NewOrderAlertBanner`.
///
/// No in-app banner like the tenant side: a new delivery already appears
/// immediately at the top of the Order home's Baru sub-tab
/// (`OrderBoardNotifier._onDeliveryCreated`), so there is nothing this needs
/// to show — only the audio/tray-notification side effect.
final class NewDeliveryAlertProvider
    extends $NotifierProvider<NewDeliveryAlert, void> {
  /// Chimes/notifies a busboy session when a new delivery lands
  /// (`delivery.created` on `private-zone.<zoneId>`) — the busboy-side mirror
  /// of `NewOrderAlertBanner`.
  ///
  /// No in-app banner like the tenant side: a new delivery already appears
  /// immediately at the top of the Order home's Baru sub-tab
  /// (`OrderBoardNotifier._onDeliveryCreated`), so there is nothing this needs
  /// to show — only the audio/tray-notification side effect.
  NewDeliveryAlertProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newDeliveryAlertProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newDeliveryAlertHash();

  @$internal
  @override
  NewDeliveryAlert create() => NewDeliveryAlert();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$newDeliveryAlertHash() => r'07df2be36d23f862951e572863e22e81cfd24b52';

/// Chimes/notifies a busboy session when a new delivery lands
/// (`delivery.created` on `private-zone.<zoneId>`) — the busboy-side mirror
/// of `NewOrderAlertBanner`.
///
/// No in-app banner like the tenant side: a new delivery already appears
/// immediately at the top of the Order home's Baru sub-tab
/// (`OrderBoardNotifier._onDeliveryCreated`), so there is nothing this needs
/// to show — only the audio/tray-notification side effect.

abstract class _$NewDeliveryAlert extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

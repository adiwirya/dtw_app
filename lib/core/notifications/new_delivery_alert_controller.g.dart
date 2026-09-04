// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_delivery_alert_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$newDeliveryAlertHash() => r'07df2be36d23f862951e572863e22e81cfd24b52';

/// Chimes/notifies a busboy session when a new delivery lands
/// (`delivery.created` on `private-zone.<zoneId>`) — the busboy-side mirror
/// of `NewOrderAlertBanner`.
///
/// No in-app banner like the tenant side: a new delivery already appears
/// immediately at the top of the Order home's Baru sub-tab
/// (`OrderBoardNotifier._onDeliveryCreated`), so there is nothing this needs
/// to show — only the audio/tray-notification side effect.
///
/// Copied from [NewDeliveryAlert].
@ProviderFor(NewDeliveryAlert)
final newDeliveryAlertProvider =
    NotifierProvider<NewDeliveryAlert, void>.internal(
      NewDeliveryAlert.new,
      name: r'newDeliveryAlertProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$newDeliveryAlertHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NewDeliveryAlert = Notifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

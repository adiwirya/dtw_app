// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_order_alert_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appLifecycleHash() => r'555476e560a7fa52d6ce4b23b11d7dd43aa9d691';

/// Reads the app's current lifecycle state. Injected so a test can drive the
/// foreground/background branch without a real binding.
///
/// `SchedulerBinding.lifecycleState` is null until the platform reports the
/// first transition, which on a cold start is *after* frames are already
/// running — treated as foregrounded by [NewOrderAlertBanner], since that is
/// what it means.
///
/// Copied from [appLifecycle].
@ProviderFor(appLifecycle)
final appLifecycleProvider = Provider<AppLifecycleState? Function()>.internal(
  appLifecycle,
  name: r'appLifecycleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appLifecycleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppLifecycleRef = ProviderRef<AppLifecycleState? Function()>;
String _$newOrderAlertBannerHash() =>
    r'c98d658e996fc3dbad52ad40d77bf1d6a647c4bf';

/// The alert currently shown as an in-app banner, or null for none.
///
/// Separate from firing the alert so the banner is pure UI state the widget
/// tree can watch, dismiss and re-show without reaching into plugins.
///
/// Copied from [NewOrderAlertBanner].
@ProviderFor(NewOrderAlertBanner)
final newOrderAlertBannerProvider =
    NotifierProvider<NewOrderAlertBanner, NewOrderAlert?>.internal(
      NewOrderAlertBanner.new,
      name: r'newOrderAlertBannerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$newOrderAlertBannerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NewOrderAlertBanner = Notifier<NewOrderAlert?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

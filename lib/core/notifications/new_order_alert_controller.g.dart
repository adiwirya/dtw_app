// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_order_alert_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reads the app's current lifecycle state. Injected so a test can drive the
/// foreground/background branch without a real binding.
///
/// `SchedulerBinding.lifecycleState` is null until the platform reports the
/// first transition, which on a cold start is *after* frames are already
/// running — treated as foregrounded by [NewOrderAlertBanner], since that is
/// what it means.

@ProviderFor(appLifecycle)
final appLifecycleProvider = AppLifecycleProvider._();

/// Reads the app's current lifecycle state. Injected so a test can drive the
/// foreground/background branch without a real binding.
///
/// `SchedulerBinding.lifecycleState` is null until the platform reports the
/// first transition, which on a cold start is *after* frames are already
/// running — treated as foregrounded by [NewOrderAlertBanner], since that is
/// what it means.

final class AppLifecycleProvider
    extends
        $FunctionalProvider<
          AppLifecycleState? Function(),
          AppLifecycleState? Function(),
          AppLifecycleState? Function()
        >
    with $Provider<AppLifecycleState? Function()> {
  /// Reads the app's current lifecycle state. Injected so a test can drive the
  /// foreground/background branch without a real binding.
  ///
  /// `SchedulerBinding.lifecycleState` is null until the platform reports the
  /// first transition, which on a cold start is *after* frames are already
  /// running — treated as foregrounded by [NewOrderAlertBanner], since that is
  /// what it means.
  AppLifecycleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLifecycleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLifecycleHash();

  @$internal
  @override
  $ProviderElement<AppLifecycleState? Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppLifecycleState? Function() create(Ref ref) {
    return appLifecycle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLifecycleState? Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLifecycleState? Function()>(
        value,
      ),
    );
  }
}

String _$appLifecycleHash() => r'555476e560a7fa52d6ce4b23b11d7dd43aa9d691';

/// The alert currently shown as an in-app banner, or null for none.
///
/// Separate from firing the alert so the banner is pure UI state the widget
/// tree can watch, dismiss and re-show without reaching into plugins.

@ProviderFor(NewOrderAlertBanner)
final newOrderAlertBannerProvider = NewOrderAlertBannerProvider._();

/// The alert currently shown as an in-app banner, or null for none.
///
/// Separate from firing the alert so the banner is pure UI state the widget
/// tree can watch, dismiss and re-show without reaching into plugins.
final class NewOrderAlertBannerProvider
    extends $NotifierProvider<NewOrderAlertBanner, NewOrderAlert?> {
  /// The alert currently shown as an in-app banner, or null for none.
  ///
  /// Separate from firing the alert so the banner is pure UI state the widget
  /// tree can watch, dismiss and re-show without reaching into plugins.
  NewOrderAlertBannerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newOrderAlertBannerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newOrderAlertBannerHash();

  @$internal
  @override
  NewOrderAlertBanner create() => NewOrderAlertBanner();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NewOrderAlert? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NewOrderAlert?>(value),
    );
  }
}

String _$newOrderAlertBannerHash() =>
    r'c98d658e996fc3dbad52ad40d77bf1d6a647c4bf';

/// The alert currently shown as an in-app banner, or null for none.
///
/// Separate from firing the alert so the banner is pure UI state the widget
/// tree can watch, dismiss and re-show without reaching into plugins.

abstract class _$NewOrderAlertBanner extends $Notifier<NewOrderAlert?> {
  NewOrderAlert? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<NewOrderAlert?, NewOrderAlert?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NewOrderAlert?, NewOrderAlert?>,
              NewOrderAlert?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

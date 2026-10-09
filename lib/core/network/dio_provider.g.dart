// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dio)
final dioProvider = DioProvider._();

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'474236ec48d7a9a4c663db3da55981368891a64c';

/// A [Dio] for the device-onboarding endpoint only
/// (`POST /v1/devices/register`) — deliberately NOT [dioProvider]. That one's
/// `onError` interceptor treats every 401 as an expired *user* session and
/// logs the whole app out (clears the auth token, disconnects realtime,
/// resets every session provider) — but a 401 on device registration means a
/// bad/misconfigured `X-Device-Key`, which has nothing to do with whichever
/// user session (if any) is already active on this device. Sharing
/// [dioProvider] would mean a device-key misconfiguration silently logs out
/// an unrelated, perfectly valid user session — the exact case the
/// onboarding gate's "mid-restore" scenario needs to NOT break. Same base
/// URL/timeouts as [dioProvider], no auth header, no session interceptor.

@ProviderFor(deviceDio)
final deviceDioProvider = DeviceDioProvider._();

/// A [Dio] for the device-onboarding endpoint only
/// (`POST /v1/devices/register`) — deliberately NOT [dioProvider]. That one's
/// `onError` interceptor treats every 401 as an expired *user* session and
/// logs the whole app out (clears the auth token, disconnects realtime,
/// resets every session provider) — but a 401 on device registration means a
/// bad/misconfigured `X-Device-Key`, which has nothing to do with whichever
/// user session (if any) is already active on this device. Sharing
/// [dioProvider] would mean a device-key misconfiguration silently logs out
/// an unrelated, perfectly valid user session — the exact case the
/// onboarding gate's "mid-restore" scenario needs to NOT break. Same base
/// URL/timeouts as [dioProvider], no auth header, no session interceptor.

final class DeviceDioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// A [Dio] for the device-onboarding endpoint only
  /// (`POST /v1/devices/register`) — deliberately NOT [dioProvider]. That one's
  /// `onError` interceptor treats every 401 as an expired *user* session and
  /// logs the whole app out (clears the auth token, disconnects realtime,
  /// resets every session provider) — but a 401 on device registration means a
  /// bad/misconfigured `X-Device-Key`, which has nothing to do with whichever
  /// user session (if any) is already active on this device. Sharing
  /// [dioProvider] would mean a device-key misconfiguration silently logs out
  /// an unrelated, perfectly valid user session — the exact case the
  /// onboarding gate's "mid-restore" scenario needs to NOT break. Same base
  /// URL/timeouts as [dioProvider], no auth header, no session interceptor.
  DeviceDioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceDioProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceDioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return deviceDio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$deviceDioHash() => r'27705b30f1095ff3b332ea2e6baab79d28748cc0';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dioHash() => r'cae141d363a97e323eee1bd3f933e83f66f7cdbb';

/// See also [dio].
@ProviderFor(dio)
final dioProvider = AutoDisposeProvider<Dio>.internal(
  dio,
  name: r'dioProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dioHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DioRef = AutoDisposeProviderRef<Dio>;
String _$deviceDioHash() => r'317033eb6d9130a7d10bc0a4c3b0d59dd8a2e68a';

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
///
/// Copied from [deviceDio].
@ProviderFor(deviceDio)
final deviceDioProvider = AutoDisposeProvider<Dio>.internal(
  deviceDio,
  name: r'deviceDioProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deviceDioHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeviceDioRef = AutoDisposeProviderRef<Dio>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

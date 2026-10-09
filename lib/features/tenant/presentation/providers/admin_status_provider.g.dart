// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Real tenant identity for the Admin status screen, fetched from
/// `GET /v1/tenant-branches/{id}`. See [TenantAdminInfo] for which fields the
/// endpoint doesn't cover yet.

@ProviderFor(tenantAdminInfo)
final tenantAdminInfoProvider = TenantAdminInfoProvider._();

/// Real tenant identity for the Admin status screen, fetched from
/// `GET /v1/tenant-branches/{id}`. See [TenantAdminInfo] for which fields the
/// endpoint doesn't cover yet.

final class TenantAdminInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<TenantAdminInfo>,
          TenantAdminInfo,
          FutureOr<TenantAdminInfo>
        >
    with $FutureModifier<TenantAdminInfo>, $FutureProvider<TenantAdminInfo> {
  /// Real tenant identity for the Admin status screen, fetched from
  /// `GET /v1/tenant-branches/{id}`. See [TenantAdminInfo] for which fields the
  /// endpoint doesn't cover yet.
  TenantAdminInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tenantAdminInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tenantAdminInfoHash();

  @$internal
  @override
  $FutureProviderElement<TenantAdminInfo> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TenantAdminInfo> create(Ref ref) {
    return tenantAdminInfo(ref);
  }
}

String _$tenantAdminInfoHash() => r'3b8946a76faaa98f73363a4dcfd3a2c449e273d6';

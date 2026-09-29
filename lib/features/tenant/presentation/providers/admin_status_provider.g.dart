// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tenantAdminInfoHash() => r'3b8946a76faaa98f73363a4dcfd3a2c449e273d6';

/// Real tenant identity for the Admin status screen, fetched from
/// `GET /v1/tenant-branches/{id}`. See [TenantAdminInfo] for which fields the
/// endpoint doesn't cover yet.
///
/// Copied from [tenantAdminInfo].
@ProviderFor(tenantAdminInfo)
final tenantAdminInfoProvider =
    AutoDisposeFutureProvider<TenantAdminInfo>.internal(
      tenantAdminInfo,
      name: r'tenantAdminInfoProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$tenantAdminInfoHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TenantAdminInfoRef = AutoDisposeFutureProviderRef<TenantAdminInfo>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tenantAdminInfoHash() => r'47bd5e33a83ffbc155d4c0d5abda88c4d38c6ed0';

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
String _$adminOnlineStatusHash() => r'12740c6c196b42bacb25176844e50fc7fa8e4e67';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$AdminOnlineStatus extends BuildlessAutoDisposeNotifier<bool> {
  late final bool initialOnline;

  bool build({bool initialOnline = false});
}

/// Mutable online/offline flag for the Admin status screen.
///
/// One screen drives both `admin-offline` and `admin-online`: toggling flips
/// this flag in place (no navigation) and the screen rebuilds into the other
/// state. The two routes are entry points, keyed by [initialOnline] so a
/// deep-link to `/admin/online` lands online while `/admin` lands offline.
///
/// Copied from [AdminOnlineStatus].
@ProviderFor(AdminOnlineStatus)
const adminOnlineStatusProvider = AdminOnlineStatusFamily();

/// Mutable online/offline flag for the Admin status screen.
///
/// One screen drives both `admin-offline` and `admin-online`: toggling flips
/// this flag in place (no navigation) and the screen rebuilds into the other
/// state. The two routes are entry points, keyed by [initialOnline] so a
/// deep-link to `/admin/online` lands online while `/admin` lands offline.
///
/// Copied from [AdminOnlineStatus].
class AdminOnlineStatusFamily extends Family<bool> {
  /// Mutable online/offline flag for the Admin status screen.
  ///
  /// One screen drives both `admin-offline` and `admin-online`: toggling flips
  /// this flag in place (no navigation) and the screen rebuilds into the other
  /// state. The two routes are entry points, keyed by [initialOnline] so a
  /// deep-link to `/admin/online` lands online while `/admin` lands offline.
  ///
  /// Copied from [AdminOnlineStatus].
  const AdminOnlineStatusFamily();

  /// Mutable online/offline flag for the Admin status screen.
  ///
  /// One screen drives both `admin-offline` and `admin-online`: toggling flips
  /// this flag in place (no navigation) and the screen rebuilds into the other
  /// state. The two routes are entry points, keyed by [initialOnline] so a
  /// deep-link to `/admin/online` lands online while `/admin` lands offline.
  ///
  /// Copied from [AdminOnlineStatus].
  AdminOnlineStatusProvider call({bool initialOnline = false}) {
    return AdminOnlineStatusProvider(initialOnline: initialOnline);
  }

  @override
  AdminOnlineStatusProvider getProviderOverride(
    covariant AdminOnlineStatusProvider provider,
  ) {
    return call(initialOnline: provider.initialOnline);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'adminOnlineStatusProvider';
}

/// Mutable online/offline flag for the Admin status screen.
///
/// One screen drives both `admin-offline` and `admin-online`: toggling flips
/// this flag in place (no navigation) and the screen rebuilds into the other
/// state. The two routes are entry points, keyed by [initialOnline] so a
/// deep-link to `/admin/online` lands online while `/admin` lands offline.
///
/// Copied from [AdminOnlineStatus].
class AdminOnlineStatusProvider
    extends AutoDisposeNotifierProviderImpl<AdminOnlineStatus, bool> {
  /// Mutable online/offline flag for the Admin status screen.
  ///
  /// One screen drives both `admin-offline` and `admin-online`: toggling flips
  /// this flag in place (no navigation) and the screen rebuilds into the other
  /// state. The two routes are entry points, keyed by [initialOnline] so a
  /// deep-link to `/admin/online` lands online while `/admin` lands offline.
  ///
  /// Copied from [AdminOnlineStatus].
  AdminOnlineStatusProvider({bool initialOnline = false})
    : this._internal(
        () => AdminOnlineStatus()..initialOnline = initialOnline,
        from: adminOnlineStatusProvider,
        name: r'adminOnlineStatusProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$adminOnlineStatusHash,
        dependencies: AdminOnlineStatusFamily._dependencies,
        allTransitiveDependencies:
            AdminOnlineStatusFamily._allTransitiveDependencies,
        initialOnline: initialOnline,
      );

  AdminOnlineStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.initialOnline,
  }) : super.internal();

  final bool initialOnline;

  @override
  bool runNotifierBuild(covariant AdminOnlineStatus notifier) {
    return notifier.build(initialOnline: initialOnline);
  }

  @override
  Override overrideWith(AdminOnlineStatus Function() create) {
    return ProviderOverride(
      origin: this,
      override: AdminOnlineStatusProvider._internal(
        () => create()..initialOnline = initialOnline,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        initialOnline: initialOnline,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<AdminOnlineStatus, bool> createElement() {
    return _AdminOnlineStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminOnlineStatusProvider &&
        other.initialOnline == initialOnline;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, initialOnline.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AdminOnlineStatusRef on AutoDisposeNotifierProviderRef<bool> {
  /// The parameter `initialOnline` of this provider.
  bool get initialOnline;
}

class _AdminOnlineStatusProviderElement
    extends AutoDisposeNotifierProviderElement<AdminOnlineStatus, bool>
    with AdminOnlineStatusRef {
  _AdminOnlineStatusProviderElement(super.provider);

  @override
  bool get initialOnline => (origin as AdminOnlineStatusProvider).initialOnline;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

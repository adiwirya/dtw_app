// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riwayat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$riwayatDaysHash() => r'f10bf372c98b6892919bd9a1b04bcc68da5f9583';

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

/// Mock history for a [RiwayatRange].
///
/// - [RiwayatRange.hariIni] → today's single day group.
/// - [RiwayatRange.kemarin] → yesterday's single day group.
/// - [RiwayatRange.tujuhHari] → both groups stacked (newest first), matching
///   the multi-day `riwayat-7-hari` reference.
///
/// Copied from [riwayatDays].
@ProviderFor(riwayatDays)
const riwayatDaysProvider = RiwayatDaysFamily();

/// Mock history for a [RiwayatRange].
///
/// - [RiwayatRange.hariIni] → today's single day group.
/// - [RiwayatRange.kemarin] → yesterday's single day group.
/// - [RiwayatRange.tujuhHari] → both groups stacked (newest first), matching
///   the multi-day `riwayat-7-hari` reference.
///
/// Copied from [riwayatDays].
class RiwayatDaysFamily extends Family<List<RiwayatDayGroup>> {
  /// Mock history for a [RiwayatRange].
  ///
  /// - [RiwayatRange.hariIni] → today's single day group.
  /// - [RiwayatRange.kemarin] → yesterday's single day group.
  /// - [RiwayatRange.tujuhHari] → both groups stacked (newest first), matching
  ///   the multi-day `riwayat-7-hari` reference.
  ///
  /// Copied from [riwayatDays].
  const RiwayatDaysFamily();

  /// Mock history for a [RiwayatRange].
  ///
  /// - [RiwayatRange.hariIni] → today's single day group.
  /// - [RiwayatRange.kemarin] → yesterday's single day group.
  /// - [RiwayatRange.tujuhHari] → both groups stacked (newest first), matching
  ///   the multi-day `riwayat-7-hari` reference.
  ///
  /// Copied from [riwayatDays].
  RiwayatDaysProvider call(RiwayatRange range) {
    return RiwayatDaysProvider(range);
  }

  @override
  RiwayatDaysProvider getProviderOverride(
    covariant RiwayatDaysProvider provider,
  ) {
    return call(provider.range);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'riwayatDaysProvider';
}

/// Mock history for a [RiwayatRange].
///
/// - [RiwayatRange.hariIni] → today's single day group.
/// - [RiwayatRange.kemarin] → yesterday's single day group.
/// - [RiwayatRange.tujuhHari] → both groups stacked (newest first), matching
///   the multi-day `riwayat-7-hari` reference.
///
/// Copied from [riwayatDays].
class RiwayatDaysProvider extends AutoDisposeProvider<List<RiwayatDayGroup>> {
  /// Mock history for a [RiwayatRange].
  ///
  /// - [RiwayatRange.hariIni] → today's single day group.
  /// - [RiwayatRange.kemarin] → yesterday's single day group.
  /// - [RiwayatRange.tujuhHari] → both groups stacked (newest first), matching
  ///   the multi-day `riwayat-7-hari` reference.
  ///
  /// Copied from [riwayatDays].
  RiwayatDaysProvider(RiwayatRange range)
    : this._internal(
        (ref) => riwayatDays(ref as RiwayatDaysRef, range),
        from: riwayatDaysProvider,
        name: r'riwayatDaysProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$riwayatDaysHash,
        dependencies: RiwayatDaysFamily._dependencies,
        allTransitiveDependencies: RiwayatDaysFamily._allTransitiveDependencies,
        range: range,
      );

  RiwayatDaysProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.range,
  }) : super.internal();

  final RiwayatRange range;

  @override
  Override overrideWith(
    List<RiwayatDayGroup> Function(RiwayatDaysRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RiwayatDaysProvider._internal(
        (ref) => create(ref as RiwayatDaysRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        range: range,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<RiwayatDayGroup>> createElement() {
    return _RiwayatDaysProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RiwayatDaysProvider && other.range == range;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, range.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RiwayatDaysRef on AutoDisposeProviderRef<List<RiwayatDayGroup>> {
  /// The parameter `range` of this provider.
  RiwayatRange get range;
}

class _RiwayatDaysProviderElement
    extends AutoDisposeProviderElement<List<RiwayatDayGroup>>
    with RiwayatDaysRef {
  _RiwayatDaysProviderElement(super.provider);

  @override
  RiwayatRange get range => (origin as RiwayatDaysProvider).range;
}

String _$riwayatDetailHash() => r'5f948db57e0dd2a254cace9c1f4c89ff7525d9d1';

/// Mock detail for the `detail-riwayat` (history entry detail) page. The frame
/// is identical to `detail-selesai` except the `Informasi Pesanan` "Tenan"
/// value, which here shows the tenant subtotal (`Rp35.000`).
///
/// Copied from [riwayatDetail].
@ProviderFor(riwayatDetail)
final riwayatDetailProvider =
    AutoDisposeProvider<CompletedOrderDetail>.internal(
      riwayatDetail,
      name: r'riwayatDetailProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$riwayatDetailHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RiwayatDetailRef = AutoDisposeProviderRef<CompletedOrderDetail>;
String _$riwayatTabHash() => r'1118aefd371c3b342a7fd644154e5476386f3e89';

/// Currently selected Riwayat date tab, as an index into
/// `[hariIni, kemarin, tujuhHari]`. Kept as app state (not screen-local) so the
/// `/riwayat/kemarin` and `/riwayat/7-hari` route deep-links can switch the
/// in-place tab. Mirrors the Order tab provider.
///
/// Copied from [RiwayatTab].
@ProviderFor(RiwayatTab)
final riwayatTabProvider =
    AutoDisposeNotifierProvider<RiwayatTab, int>.internal(
      RiwayatTab.new,
      name: r'riwayatTabProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$riwayatTabHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RiwayatTab = AutoDisposeNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

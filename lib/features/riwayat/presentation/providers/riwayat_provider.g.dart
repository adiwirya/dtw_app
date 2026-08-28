// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riwayat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$riwayatDetailHash() => r'2caa0ee90e29bce0d3626a6f5987eab0ca38ad16';

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

/// Looks [entryId] (a delivery id) up out of the same list
/// [riwayatBoardProvider] holds — null while the board is still loading, has
/// errored, or the delivery isn't on it.
///
/// Copied from [riwayatDetail].
@ProviderFor(riwayatDetail)
const riwayatDetailProvider = RiwayatDetailFamily();

/// Looks [entryId] (a delivery id) up out of the same list
/// [riwayatBoardProvider] holds — null while the board is still loading, has
/// errored, or the delivery isn't on it.
///
/// Copied from [riwayatDetail].
class RiwayatDetailFamily extends Family<CompletedOrderDetail?> {
  /// Looks [entryId] (a delivery id) up out of the same list
  /// [riwayatBoardProvider] holds — null while the board is still loading, has
  /// errored, or the delivery isn't on it.
  ///
  /// Copied from [riwayatDetail].
  const RiwayatDetailFamily();

  /// Looks [entryId] (a delivery id) up out of the same list
  /// [riwayatBoardProvider] holds — null while the board is still loading, has
  /// errored, or the delivery isn't on it.
  ///
  /// Copied from [riwayatDetail].
  RiwayatDetailProvider call(String entryId) {
    return RiwayatDetailProvider(entryId);
  }

  @override
  RiwayatDetailProvider getProviderOverride(
    covariant RiwayatDetailProvider provider,
  ) {
    return call(provider.entryId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'riwayatDetailProvider';
}

/// Looks [entryId] (a delivery id) up out of the same list
/// [riwayatBoardProvider] holds — null while the board is still loading, has
/// errored, or the delivery isn't on it.
///
/// Copied from [riwayatDetail].
class RiwayatDetailProvider extends AutoDisposeProvider<CompletedOrderDetail?> {
  /// Looks [entryId] (a delivery id) up out of the same list
  /// [riwayatBoardProvider] holds — null while the board is still loading, has
  /// errored, or the delivery isn't on it.
  ///
  /// Copied from [riwayatDetail].
  RiwayatDetailProvider(String entryId)
    : this._internal(
        (ref) => riwayatDetail(ref as RiwayatDetailRef, entryId),
        from: riwayatDetailProvider,
        name: r'riwayatDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$riwayatDetailHash,
        dependencies: RiwayatDetailFamily._dependencies,
        allTransitiveDependencies:
            RiwayatDetailFamily._allTransitiveDependencies,
        entryId: entryId,
      );

  RiwayatDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.entryId,
  }) : super.internal();

  final String entryId;

  @override
  Override overrideWith(
    CompletedOrderDetail? Function(RiwayatDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RiwayatDetailProvider._internal(
        (ref) => create(ref as RiwayatDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        entryId: entryId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<CompletedOrderDetail?> createElement() {
    return _RiwayatDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RiwayatDetailProvider && other.entryId == entryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, entryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RiwayatDetailRef on AutoDisposeProviderRef<CompletedOrderDetail?> {
  /// The parameter `entryId` of this provider.
  String get entryId;
}

class _RiwayatDetailProviderElement
    extends AutoDisposeProviderElement<CompletedOrderDetail?>
    with RiwayatDetailRef {
  _RiwayatDetailProviderElement(super.provider);

  @override
  String get entryId => (origin as RiwayatDetailProvider).entryId;
}

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
String _$riwayatBoardHash() => r'b7269350f8e7638dc583dc2785a5294900e235eb';

/// The busboy's completed-delivery history, fetched once from
/// `GET /api/v1/busboy/deliveries?status=DELIVERED`. [riwayatDaysFrom]
/// buckets this same list by date for each [RiwayatRange] tab, and
/// [riwayatDetailProvider] looks a single entry up out of it.
///
/// TODO(open-question): the busboy API has no date-range query param, so
/// this fetches every DELIVERED delivery (unbounded, no pagination) and
/// buckets by date client-side — fine for now, but will need a real
/// range/pagination param from backend once delivery history grows large.
///
/// Copied from [RiwayatBoard].
@ProviderFor(RiwayatBoard)
final riwayatBoardProvider =
    AutoDisposeAsyncNotifierProvider<RiwayatBoard, List<Delivery>>.internal(
      RiwayatBoard.new,
      name: r'riwayatBoardProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$riwayatBoardHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RiwayatBoard = AutoDisposeAsyncNotifier<List<Delivery>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

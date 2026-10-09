// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riwayat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Currently selected Riwayat date tab, as an index into
/// `[hariIni, kemarin, tujuhHari]`. Kept as app state (not screen-local) so the
/// `/riwayat/kemarin` and `/riwayat/7-hari` route deep-links can switch the
/// in-place tab. Mirrors the Order tab provider.

@ProviderFor(RiwayatTab)
final riwayatTabProvider = RiwayatTabProvider._();

/// Currently selected Riwayat date tab, as an index into
/// `[hariIni, kemarin, tujuhHari]`. Kept as app state (not screen-local) so the
/// `/riwayat/kemarin` and `/riwayat/7-hari` route deep-links can switch the
/// in-place tab. Mirrors the Order tab provider.
final class RiwayatTabProvider extends $NotifierProvider<RiwayatTab, int> {
  /// Currently selected Riwayat date tab, as an index into
  /// `[hariIni, kemarin, tujuhHari]`. Kept as app state (not screen-local) so the
  /// `/riwayat/kemarin` and `/riwayat/7-hari` route deep-links can switch the
  /// in-place tab. Mirrors the Order tab provider.
  RiwayatTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'riwayatTabProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$riwayatTabHash();

  @$internal
  @override
  RiwayatTab create() => RiwayatTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$riwayatTabHash() => r'1118aefd371c3b342a7fd644154e5476386f3e89';

/// Currently selected Riwayat date tab, as an index into
/// `[hariIni, kemarin, tujuhHari]`. Kept as app state (not screen-local) so the
/// `/riwayat/kemarin` and `/riwayat/7-hari` route deep-links can switch the
/// in-place tab. Mirrors the Order tab provider.

abstract class _$RiwayatTab extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// This busboy's own completed-delivery history, fetched once from
/// `GET /v1/busboy/deliveries/history?status=DELIVERED` — scoped to the
/// logged-in busboy, unlike the Order tab's `GET /v1/busboy/deliveries`
/// (everyone in the zone). [riwayatDaysFrom] buckets this same list by date
/// for each [RiwayatRange] tab, and [riwayatDetailProvider] looks a single
/// entry up out of it.
// The endpoint takes `from`/`to` (`YYYY-MM-DD`); only the last 7 days are ever
// shown, so `from` is set to 8 days ago (one day of slack for UTC vs. local
// dates) and [riwayatDaysFrom] still does the exact bucketing client-side.

@ProviderFor(RiwayatBoard)
final riwayatBoardProvider = RiwayatBoardProvider._();

/// This busboy's own completed-delivery history, fetched once from
/// `GET /v1/busboy/deliveries/history?status=DELIVERED` — scoped to the
/// logged-in busboy, unlike the Order tab's `GET /v1/busboy/deliveries`
/// (everyone in the zone). [riwayatDaysFrom] buckets this same list by date
/// for each [RiwayatRange] tab, and [riwayatDetailProvider] looks a single
/// entry up out of it.
// The endpoint takes `from`/`to` (`YYYY-MM-DD`); only the last 7 days are ever
// shown, so `from` is set to 8 days ago (one day of slack for UTC vs. local
// dates) and [riwayatDaysFrom] still does the exact bucketing client-side.
final class RiwayatBoardProvider
    extends $AsyncNotifierProvider<RiwayatBoard, List<Delivery>> {
  /// This busboy's own completed-delivery history, fetched once from
  /// `GET /v1/busboy/deliveries/history?status=DELIVERED` — scoped to the
  /// logged-in busboy, unlike the Order tab's `GET /v1/busboy/deliveries`
  /// (everyone in the zone). [riwayatDaysFrom] buckets this same list by date
  /// for each [RiwayatRange] tab, and [riwayatDetailProvider] looks a single
  /// entry up out of it.
  // The endpoint takes `from`/`to` (`YYYY-MM-DD`); only the last 7 days are ever
  // shown, so `from` is set to 8 days ago (one day of slack for UTC vs. local
  // dates) and [riwayatDaysFrom] still does the exact bucketing client-side.
  RiwayatBoardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'riwayatBoardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$riwayatBoardHash();

  @$internal
  @override
  RiwayatBoard create() => RiwayatBoard();
}

String _$riwayatBoardHash() => r'519732e865c2f67ca40edbd1a79f20d9fbe64ec0';

/// This busboy's own completed-delivery history, fetched once from
/// `GET /v1/busboy/deliveries/history?status=DELIVERED` — scoped to the
/// logged-in busboy, unlike the Order tab's `GET /v1/busboy/deliveries`
/// (everyone in the zone). [riwayatDaysFrom] buckets this same list by date
/// for each [RiwayatRange] tab, and [riwayatDetailProvider] looks a single
/// entry up out of it.
// The endpoint takes `from`/`to` (`YYYY-MM-DD`); only the last 7 days are ever
// shown, so `from` is set to 8 days ago (one day of slack for UTC vs. local
// dates) and [riwayatDaysFrom] still does the exact bucketing client-side.

abstract class _$RiwayatBoard extends $AsyncNotifier<List<Delivery>> {
  FutureOr<List<Delivery>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Delivery>>, List<Delivery>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Delivery>>, List<Delivery>>,
              AsyncValue<List<Delivery>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Looks [entryId] (a delivery id) up out of the same list
/// [riwayatBoardProvider] holds — null while the board is still loading, has
/// errored, or the delivery isn't on it.

@ProviderFor(riwayatDetail)
final riwayatDetailProvider = RiwayatDetailFamily._();

/// Looks [entryId] (a delivery id) up out of the same list
/// [riwayatBoardProvider] holds — null while the board is still loading, has
/// errored, or the delivery isn't on it.

final class RiwayatDetailProvider
    extends
        $FunctionalProvider<
          CompletedOrderDetail?,
          CompletedOrderDetail?,
          CompletedOrderDetail?
        >
    with $Provider<CompletedOrderDetail?> {
  /// Looks [entryId] (a delivery id) up out of the same list
  /// [riwayatBoardProvider] holds — null while the board is still loading, has
  /// errored, or the delivery isn't on it.
  RiwayatDetailProvider._({
    required RiwayatDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'riwayatDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$riwayatDetailHash();

  @override
  String toString() {
    return r'riwayatDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<CompletedOrderDetail?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CompletedOrderDetail? create(Ref ref) {
    final argument = this.argument as String;
    return riwayatDetail(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CompletedOrderDetail? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CompletedOrderDetail?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RiwayatDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$riwayatDetailHash() => r'3adde5307bb86946ff0368f0c903a79d1dfac74a';

/// Looks [entryId] (a delivery id) up out of the same list
/// [riwayatBoardProvider] holds — null while the board is still loading, has
/// errored, or the delivery isn't on it.

final class RiwayatDetailFamily extends $Family
    with $FunctionalFamilyOverride<CompletedOrderDetail?, String> {
  RiwayatDetailFamily._()
    : super(
        retry: null,
        name: r'riwayatDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Looks [entryId] (a delivery id) up out of the same list
  /// [riwayatBoardProvider] holds — null while the board is still loading, has
  /// errored, or the delivery isn't on it.

  RiwayatDetailProvider call(String entryId) =>
      RiwayatDetailProvider._(argument: entryId, from: this);

  @override
  String toString() => r'riwayatDetailProvider';
}

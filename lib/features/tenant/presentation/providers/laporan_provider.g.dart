// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'laporan_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Mock backing data for the tenant `laporan` (report dashboard) frame.

@ProviderFor(laporanReport)
final laporanReportProvider = LaporanReportProvider._();

/// Mock backing data for the tenant `laporan` (report dashboard) frame.

final class LaporanReportProvider
    extends $FunctionalProvider<LaporanReport, LaporanReport, LaporanReport>
    with $Provider<LaporanReport> {
  /// Mock backing data for the tenant `laporan` (report dashboard) frame.
  LaporanReportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'laporanReportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$laporanReportHash();

  @$internal
  @override
  $ProviderElement<LaporanReport> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LaporanReport create(Ref ref) {
    return laporanReport(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LaporanReport value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LaporanReport>(value),
    );
  }
}

String _$laporanReportHash() => r'7777b23020c23307b1fd5ed525ef725e48dfd4e2';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'busboy_delivery_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(busboyDeliveryRepository)
final busboyDeliveryRepositoryProvider = BusboyDeliveryRepositoryProvider._();

final class BusboyDeliveryRepositoryProvider
    extends
        $FunctionalProvider<
          BusboyDeliveryRepository,
          BusboyDeliveryRepository,
          BusboyDeliveryRepository
        >
    with $Provider<BusboyDeliveryRepository> {
  BusboyDeliveryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'busboyDeliveryRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$busboyDeliveryRepositoryHash();

  @$internal
  @override
  $ProviderElement<BusboyDeliveryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BusboyDeliveryRepository create(Ref ref) {
    return busboyDeliveryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BusboyDeliveryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BusboyDeliveryRepository>(value),
    );
  }
}

String _$busboyDeliveryRepositoryHash() =>
    r'58cc826d37305216315d59609792efa0a4fe2eb3';

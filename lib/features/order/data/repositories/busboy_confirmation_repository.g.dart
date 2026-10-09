// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'busboy_confirmation_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(busboyConfirmationRepository)
final busboyConfirmationRepositoryProvider =
    BusboyConfirmationRepositoryProvider._();

final class BusboyConfirmationRepositoryProvider
    extends
        $FunctionalProvider<
          BusboyConfirmationRepository,
          BusboyConfirmationRepository,
          BusboyConfirmationRepository
        >
    with $Provider<BusboyConfirmationRepository> {
  BusboyConfirmationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'busboyConfirmationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$busboyConfirmationRepositoryHash();

  @$internal
  @override
  $ProviderElement<BusboyConfirmationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BusboyConfirmationRepository create(Ref ref) {
    return busboyConfirmationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BusboyConfirmationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BusboyConfirmationRepository>(value),
    );
  }
}

String _$busboyConfirmationRepositoryHash() =>
    r'dfb77aa10b095b01e59734be886acea36cdbacda';

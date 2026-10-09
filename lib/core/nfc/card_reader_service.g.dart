// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_reader_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cardReaderService)
final cardReaderServiceProvider = CardReaderServiceProvider._();

final class CardReaderServiceProvider
    extends
        $FunctionalProvider<
          CardReaderService,
          CardReaderService,
          CardReaderService
        >
    with $Provider<CardReaderService> {
  CardReaderServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cardReaderServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cardReaderServiceHash();

  @$internal
  @override
  $ProviderElement<CardReaderService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CardReaderService create(Ref ref) {
    return cardReaderService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CardReaderService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CardReaderService>(value),
    );
  }
}

String _$cardReaderServiceHash() => r'8d4c050b4a24c3e43d60ac2a3f5547c051849857';

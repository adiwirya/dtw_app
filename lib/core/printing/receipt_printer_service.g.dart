// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_printer_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(receiptPrinterService)
final receiptPrinterServiceProvider = ReceiptPrinterServiceProvider._();

final class ReceiptPrinterServiceProvider
    extends
        $FunctionalProvider<
          ReceiptPrinterService,
          ReceiptPrinterService,
          ReceiptPrinterService
        >
    with $Provider<ReceiptPrinterService> {
  ReceiptPrinterServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptPrinterServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptPrinterServiceHash();

  @$internal
  @override
  $ProviderElement<ReceiptPrinterService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptPrinterService create(Ref ref) {
    return receiptPrinterService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptPrinterService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptPrinterService>(value),
    );
  }
}

String _$receiptPrinterServiceHash() =>
    r'96c0b7d620d4c69b07de3a6885c0824ec8396e8f';

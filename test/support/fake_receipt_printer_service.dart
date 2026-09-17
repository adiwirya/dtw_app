import 'package:dtw_app/core/printing/receipt_printer_service.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';

/// One recorded [FakeReceiptPrinterService.printOrder] call.
class PrintedReceipt {
  PrintedReceipt(
    this.order, {
    required this.brandName,
    required this.areaName,
    required this.locationCode,
  });

  final TenantOrder order;
  final String brandName;
  final String areaName;
  final String locationCode;
}

/// In-memory [ReceiptPrinterService] test double. Records every call so a
/// test can assert the accept flow wires printing without a real Sunmi
/// platform channel.
class FakeReceiptPrinterService implements ReceiptPrinterService {
  final List<PrintedReceipt> printed = [];

  @override
  Future<void> printOrder(
    TenantOrder order, {
    required String brandName,
    required String areaName,
    required String locationCode,
  }) async {
    printed.add(
      PrintedReceipt(
        order,
        brandName: brandName,
        areaName: areaName,
        locationCode: locationCode,
      ),
    );
  }
}

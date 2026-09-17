import 'dart:io';

import 'package:dtw_app/core/utils/currency.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sunmi_utils/sunmi_utils.dart';

part 'receipt_printer_service.g.dart';

/// One line of a receipt, independent of the Sunmi SDK — see
/// [buildReceiptLines], which is the part of this file worth unit testing.
sealed class ReceiptLine {
  const ReceiptLine();
}

/// A single line of text.
class ReceiptText extends ReceiptLine {
  const ReceiptText(
    this.text, {
    this.align = SunmiAlign.left,
    this.bold = false,
    this.size = SunmiFontSize.md,
  });

  final String text;
  final SunmiAlign align;
  final bool bold;
  final SunmiFontSize size;
}

/// One row of columns (qty/name/price and similar), via
/// `SunmiPrinter.printTable`.
class ReceiptRow extends ReceiptLine {
  const ReceiptRow(this.columns, {this.bold = false});

  final List<SunmiColumn> columns;
  final bool bold;
}

/// A full-width dashed divider.
class ReceiptDivider extends ReceiptLine {
  const ReceiptDivider();
}

/// Blank line feed.
class ReceiptFeed extends ReceiptLine {
  const ReceiptFeed([this.lines = 1]);

  final int lines;
}

/// Dash count for [ReceiptDivider] — standard 58mm thermal paper width in
/// the printer's default font.
const _dividerWidth = 32;

/// Builds the bon (order receipt) print sequence for a tenant's newly
/// accepted [order] — matches the `DTW-Order` Figma "Order Normal" receipt
/// frame (node `2188:5822`).
///
/// [brandName]/[areaName]/[locationCode] come from the tenant's own
/// `TenantBranch` (a tenant session is scoped to one branch, unlike the
/// busboy side): `GET /v1/tenant-branches/{id}`'s `brand_name`, `area_name`
/// and `kd_lokasi`.
///
/// The design also shows per-item modifier bullets and a quoted customer
/// note under an item. Both are omitted here — `GET /v1/orders`' item shape
/// carries neither today (see [TenantOrder]/`OrderLineItem`), and this
/// project only models a field once it's confirmed live.
List<ReceiptLine> buildReceiptLines(
  TenantOrder order, {
  required String brandName,
  required String areaName,
  required String locationCode,
}) {
  final lines = <ReceiptLine>[
    const ReceiptText(
      'DTW ORDER',
      align: SunmiAlign.center,
      bold: true,
      size: SunmiFontSize.xl,
    ),
    ReceiptText(brandName, align: SunmiAlign.center),
    ReceiptText(
      '${areaName.toUpperCase()} - ${locationCode.toUpperCase()}',
      align: SunmiAlign.center,
      size: SunmiFontSize.sm,
    ),
    const ReceiptFeed(),
    ReceiptText(
      '#${order.receiptNumber}',
      align: SunmiAlign.center,
      bold: true,
      size: SunmiFontSize.lg,
    ),
    const ReceiptFeed(),
    ReceiptText(
      'No Meja : ${order.tableNumber ?? '-'}',
      size: SunmiFontSize.sm,
    ),
    ReceiptText(
      'Tanggal Order : ${_formatOrderTime(order.createdAt)}',
      size: SunmiFontSize.sm,
    ),
    const ReceiptDivider(),
  ];

  for (final item in order.items) {
    lines.add(
      ReceiptRow([
        SunmiColumn('${item.qty}x', width: 1),
        SunmiColumn(item.name, width: 5),
        SunmiColumn(
          _plainAmount(item.subtotal),
          width: 3,
          align: SunmiAlign.right,
        ),
      ]),
    );
  }

  lines.addAll([
    const ReceiptDivider(),
    ReceiptRow([
      const SunmiColumn('Subtotal', width: 1),
      SunmiColumn(
        _plainAmount(order.grandTotal),
        width: 1,
        align: SunmiAlign.right,
      ),
    ], bold: true),
    ReceiptRow([
      const SunmiColumn('Total', width: 1),
      SunmiColumn(
        _plainAmount(order.grandTotal),
        width: 1,
        align: SunmiAlign.right,
      ),
    ], bold: true),
    const ReceiptDivider(),
    const ReceiptFeed(3),
  ]);

  return lines;
}

/// `Rp95.000` -> `95.000` — the design prints bare amounts, no currency
/// prefix.
String _plainAmount(int value) => formatRupiah(value).replaceFirst('Rp', '');

/// `5 Sep 2026 12:35` — compact, abbreviated-month form for the narrow
/// receipt; deliberately not `Delivery.formatDate`'s full month name.
String _formatOrderTime(DateTime at) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  final hh = at.hour.toString().padLeft(2, '0');
  final mm = at.minute.toString().padLeft(2, '0');
  return '${at.day} ${months[at.month - 1]} ${at.year} $hh:$mm';
}

/// Prints the bon for a tenant accepting an incoming [TenantOrder].
// ignore: one_member_abstracts
abstract class ReceiptPrinterService {
  Future<void> printOrder(
    TenantOrder order, {
    required String brandName,
    required String areaName,
    required String locationCode,
  });
}

/// Sunmi built-in thermal printer implementation. A no-op off Android (the
/// hardware only exists on Sunmi Android devices).
class SunmiReceiptPrinterService implements ReceiptPrinterService {
  SunmiReceiptPrinterService({bool? isAndroid})
      : _isAndroid = isAndroid ?? Platform.isAndroid;

  final bool _isAndroid;

  @override
  Future<void> printOrder(
    TenantOrder order, {
    required String brandName,
    required String areaName,
    required String locationCode,
  }) async {
    if (!_isAndroid) return;
    await SunmiPrinter.initPrinter();
    for (final line in buildReceiptLines(
      order,
      brandName: brandName,
      areaName: areaName,
      locationCode: locationCode,
    )) {
      switch (line) {
        case ReceiptText():
          await SunmiPrinter.setAlignment(line.align);
          await SunmiPrinter.setBold(line.bold);
          await SunmiPrinter.setFontSize(line.size.value);
          await SunmiPrinter.printText(line.text);
        case ReceiptRow():
          await SunmiPrinter.setBold(line.bold);
          await SunmiPrinter.printTable(line.columns);
        case ReceiptDivider():
          await SunmiPrinter.setAlignment(SunmiAlign.left);
          await SunmiPrinter.setBold(false);
          await SunmiPrinter.setFontSize(SunmiFontSize.sm.value);
          await SunmiPrinter.printText('-' * _dividerWidth);
        case ReceiptFeed():
          await SunmiPrinter.lineWrap(line.lines);
      }
    }
    await SunmiPrinter.feedPaper();
  }
}

@Riverpod(keepAlive: true)
ReceiptPrinterService receiptPrinterService(Ref ref) =>
    SunmiReceiptPrinterService();

import 'package:dtw_app/core/printing/receipt_printer_service.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/incoming_order_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunmi_utils/sunmi_utils.dart';

TenantOrder _order({String? tableNumber = '2', String? customerName}) =>
    TenantOrder(
      customerName: customerName,
      id: 'order-1',
      orderGroupId: 'group-1',
      branchId: 'branch-1',
      receiptNumber: 'PRN-6327',
      tableNumber: tableNumber,
      grandTotal: 90000,
      status: TenantOrderStatus.pending,
      createdAt: DateTime(2026, 9, 5, 12, 35),
      items: const [
        OrderLineItem(
          id: 'item-1',
          name: 'Paket Super Besar',
          price: 'Rp90.000',
          subtotal: 90000,
          qty: 2,
        ),
      ],
    );

/// Concatenates every [ReceiptText]/[ReceiptRow]'s printable text, in
/// order — enough to assert on content without coupling to font/align enums.
List<String> _textsOf(List<ReceiptLine> lines) => [
  for (final line in lines)
    switch (line) {
      ReceiptText() => line.text,
      ReceiptRow() => line.columns.map((c) => c.text).join(' | '),
      ReceiptDivider() => '---',
      ReceiptFeed() => '',
    },
];

void main() {
  group('buildReceiptLines', () {
    List<String> receiptTexts(TenantOrder order) => _textsOf(
      buildReceiptLines(
        order,
        brandName: 'Ayam Betutu Khas Gilimanuk Bali',
        areaName: 'Downtown',
        locationCode: 'SMB',
      ),
    );

    test('prints only the Total row in large type', () {
      final lines = buildReceiptLines(
        _order(),
        brandName: 'Ayam Betutu Khas Gilimanuk Bali',
        areaName: 'Downtown',
        locationCode: 'SMB',
      );
      ReceiptRow rowStarting(String label) => lines
          .whereType<ReceiptRow>()
          .firstWhere((r) => r.columns.first.text == label);

      expect(rowStarting('Total').size, SunmiFontSize.lg);
      expect(rowStarting('Subtotal').size, isNull);
    });

    test('prints the customer name under the table when known', () {
      final texts = receiptTexts(_order(customerName: 'Budi Santoso'));

      final table = texts.indexOf('No Meja : 2');
      expect(texts[table + 1], 'Nama : Budi Santoso');
    });

    test('omits the customer line when there is no name', () {
      expect(
        receiptTexts(_order()).where((t) => t.startsWith('Nama')),
        isEmpty,
      );
      expect(
        receiptTexts(
          _order(customerName: '  '),
        ).where((t) => t.startsWith('Nama')),
        isEmpty,
      );
    });

    test('matches the Figma "Order Normal" bon layout', () {
      final texts = _textsOf(
        buildReceiptLines(
          _order(),
          brandName: 'Ayam Betutu Khas Gilimanuk Bali',
          areaName: 'Downtown',
          locationCode: 'SMB',
        ),
      );

      expect(texts, [
        'Click N Dine',
        'Ayam Betutu Khas Gilimanuk Bali',
        'DOWNTOWN - SMB',
        '', // feed
        '#PRN-6327',
        '', // feed
        'No Meja : 2',
        'Tanggal Order : 5 Sep 2026 12:35',
        '---',
        '2x | Paket Super Besar | 90.000',
        '---',
        'Subtotal | 90.000',
        'Total | 90.000',
        '---',
        '', // feed
      ]);
    });

    test('falls back to "-" when the order has no table number', () {
      final texts = _textsOf(
        buildReceiptLines(
          _order(tableNumber: null),
          brandName: 'Solaria',
          areaName: 'Downtown',
          locationCode: 'SMB',
        ),
      );

      expect(texts, contains('No Meja : -'));
    });
  });
}

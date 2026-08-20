import 'package:dtw_app/core/utils/currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseRupiah', () {
    test('null (no add-on price / Gratis) parses to 0', () {
      expect(parseRupiah(null), 0);
    });

    test('parses a formatRupiah-formatted string back to its int value', () {
      expect(parseRupiah(formatRupiah(3000)), 3000);
      expect(parseRupiah(formatRupiah(1500000)), 1500000);
    });

    test('parses "Rp3.000" directly', () {
      expect(parseRupiah('Rp3.000'), 3000);
    });

    test('empty string parses to 0', () {
      expect(parseRupiah(''), 0);
    });
  });
}

import 'package:dtw_app/features/performa/data/models/performa_dashboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyTarget.progress', () {
    test('divides current by total', () {
      const target = DailyTarget(
        current: 30,
        total: 40,
        unit: 'pesanan',
        caption: 'Target harian',
      );

      expect(target.progress, 0.75);
    });

    test('is 0 when total is 0, instead of dividing by zero', () {
      const target = DailyTarget(
        current: 0,
        total: 0,
        unit: 'pesanan',
        caption: 'Target harian',
      );

      expect(target.progress, 0);
    });
  });
}

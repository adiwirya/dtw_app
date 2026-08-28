import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Every screen writes bare `TextStyle(fontSize:, fontWeight:, color:)` with
  // no family and relies on `Text` merging it onto the ambient
  // `DefaultTextStyle`, which Material takes from this theme. If the family
  // ever falls off the theme, ~200 styles silently revert to the platform
  // default with nothing else to catch it.
  group('AppTheme carries the design body family', () {
    test('light', () {
      final textTheme = AppTheme.light.textTheme;
      expect(textTheme.bodyMedium?.fontFamily, AppTheme.fontFamily);
      expect(textTheme.titleLarge?.fontFamily, AppTheme.fontFamily);
    });

    test('dark', () {
      expect(
        AppTheme.dark.textTheme.bodyMedium?.fontFamily,
        AppTheme.fontFamily,
      );
    });
  });
}

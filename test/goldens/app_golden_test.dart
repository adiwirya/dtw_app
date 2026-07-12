import 'package:dtw_app/app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Login screen matches golden',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ProviderScope(child: App()));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(App),
        matchesGoldenFile('home_screen.png'),
      );
    },
    tags: 'golden',
  );
}

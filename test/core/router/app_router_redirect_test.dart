import 'package:dtw_app/app.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'a mid-session logout (e.g. from a 401) redirects to the login screen',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(isLoggedInProvider.notifier).state = true;

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await tester.pumpAndSettle();

    // Starts logged in, landed on the busboy Order tab.
    expect(find.text('Ambil'), findsOneWidget);

    // Simulate the dio 401 interceptor clearing the session.
    container.read(isLoggedInProvider.notifier).state = false;
    await tester.pumpAndSettle();

    expect(find.text('Masuk Sebagai'), findsOneWidget);
  });
}

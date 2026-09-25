import 'package:dtw_app/core/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the message and a Coba lagi button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(message: 'Terjadi kesalahan.', onRetry: () {}),
        ),
      ),
    );

    expect(find.text('Terjadi kesalahan.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('tapping Coba lagi invokes onRetry', (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(
            message: 'Terjadi kesalahan.',
            onRetry: () => retried++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Coba lagi'));
    await tester.pump();

    expect(retried, 1);
  });
}

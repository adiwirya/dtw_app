import 'package:dtw_app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders the home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('dtw_app'), findsOneWidget);
    expect(find.text('Ready to build features.'), findsOneWidget);
  });
}

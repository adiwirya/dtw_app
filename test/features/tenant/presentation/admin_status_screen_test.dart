import 'package:dtw_app/features/tenant/presentation/screens/admin_status_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({bool initialOnline = false}) => ProviderScope(
      child: MaterialApp(
        home: AdminStatusScreen(initialOnline: initialOnline),
      ),
    );

void main() {
  group('AdminStatusScreen', () {
    testWidgets('offline entry point renders the OFFLINE state',
        (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump();

      expect(find.text('KFC Fried Chicken'), findsOneWidget);
      expect(find.text('Booth B1'), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget); // hero pill
      expect(find.text('OFFLINE'), findsOneWidget); // status card heading
      expect(find.text('Set Online'), findsOneWidget);
      expect(find.text('Jam Operasional'), findsOneWidget);
      expect(find.text('10:00 - 22:00 WIB'), findsOneWidget);
      expect(find.text('Informasi Tenant'), findsOneWidget);
      expect(find.text('24 April 2024'), findsOneWidget);
      expect(find.text('+6282394627322'), findsOneWidget);
    });

    testWidgets('online entry point renders the ONLINE state', (tester) async {
      await tester.pumpWidget(_host(initialOnline: true));
      await tester.pump();

      expect(find.text('Online'), findsOneWidget); // hero pill
      expect(find.text('ONLINE'), findsOneWidget); // status card heading
      expect(find.text('Set Offline'), findsOneWidget);
      expect(find.text('OFFLINE'), findsNothing);
    });

    testWidgets('Set Online flips offline -> online in place', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump();

      expect(find.text('OFFLINE'), findsOneWidget);

      await tester.tap(find.text('Set Online'));
      await tester.pump();

      // Same screen, no navigation: hero pill + status card now read online.
      expect(find.text('ONLINE'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Set Offline'), findsOneWidget);
      expect(find.text('OFFLINE'), findsNothing);
    });

    testWidgets('Set Offline flips online -> offline in place', (tester) async {
      await tester.pumpWidget(_host(initialOnline: true));
      await tester.pump();

      await tester.tap(find.text('Set Offline'));
      await tester.pump();

      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.text('Set Online'), findsOneWidget);
    });
  });
}

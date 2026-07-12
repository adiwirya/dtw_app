import 'package:dtw_app/features/tenant/presentation/widgets/online_status_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 358, child: child)),
      ),
    );

void main() {
  group('OnlineStatusToggle', () {
    testWidgets('online: ONLINE heading + Set Offline button', (tester) async {
      await tester.pumpWidget(
        _host(OnlineStatusToggle(online: true, onToggle: (_) {})),
      );

      expect(find.text('Status Tenant'), findsOneWidget);
      expect(find.text('ONLINE'), findsOneWidget);
      expect(find.text('Set Offline'), findsOneWidget);
      expect(find.text('OFFLINE'), findsNothing);
      expect(find.text('Set Online'), findsNothing);
    });

    testWidgets('offline: OFFLINE heading + Set Online button', (tester) async {
      await tester.pumpWidget(
        _host(OnlineStatusToggle(online: false, onToggle: (_) {})),
      );

      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.text('Set Online'), findsOneWidget);
    });

    testWidgets('online: Set Offline requests offline (false)', (tester) async {
      bool? requested;
      await tester.pumpWidget(
        _host(OnlineStatusToggle(online: true, onToggle: (v) => requested = v)),
      );

      await tester.tap(find.text('Set Offline'));
      await tester.pump();
      expect(requested, isFalse);
    });

    testWidgets('offline: Set Online requests online (true)', (tester) async {
      bool? requested;
      await tester.pumpWidget(
        _host(
          OnlineStatusToggle(online: false, onToggle: (v) => requested = v),
        ),
      );

      await tester.tap(find.text('Set Online'));
      await tester.pump();
      expect(requested, isTrue);
    });
  });
}

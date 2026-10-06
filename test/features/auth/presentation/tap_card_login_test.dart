import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/nfc/card_reader_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/auth/data/repositories/auth_repository.dart';
import 'package:dtw_app/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/canned_dio.dart';
import '../../../support/fake_card_reader_service.dart';
import '../../../support/fake_local_storage.dart';

const _tapLabel = 'Masuk dengan Tap Kartu';

const Map<String, Object?> _okBody = {
  'meta': {'success': true, 'message': 'Success', 'code': 200, 'trace_id': 'a'},
  'data': {
    'access_token': 'tok_card',
    'user': {'id': 'u1', 'username': null, 'role': 'busboy'},
    'abilities': <dynamic>[],
    'scopes': <dynamic>[],
  },
};

const Map<String, Object?> _unauthorizedBody = {
  'meta': {'success': false, 'message': 'Unauthorized', 'code': 401},
  'errors': null,
};

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required FakeCardReaderService reader,
  int statusCode = 200,
  Object? body = _okBody,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final storage = FakeLocalStorage();
  final container = ProviderContainer(
    overrides: [
      cardReaderServiceProvider.overrideWithValue(reader),
      localStorageProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(
        AuthRepository(
          dio: cannedDio(statusCode, body),
          localStorage: storage,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/login',
          routes: [
            GoRoute(
              path: '/login',
              name: 'login',
              builder: (_, _) => const LoginScreen(),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.ensureVisible(find.text(_tapLabel));
  await tester.tap(find.text(_tapLabel));
  await tester.pumpAndSettle();
}

void main() {
  group('Masuk dengan Tap Kartu button', () {
    testWidgets('is shown when the device has NFC', (tester) async {
      await _pump(tester, reader: FakeCardReaderService());

      expect(find.text(_tapLabel), findsOneWidget);
      expect(find.text('atau'), findsOneWidget);
    });

    testWidgets('is hidden when the device has no NFC', (tester) async {
      await _pump(
        tester,
        reader: FakeCardReaderService(
          state: CardReaderAvailability.unsupported,
        ),
      );

      expect(find.text(_tapLabel), findsNothing);
      expect(find.text('atau'), findsNothing);
    });
  });

  group('tap card sheet', () {
    testWidgets('opens waiting for a card', (tester) async {
      final reader = FakeCardReaderService();
      await _pump(tester, reader: reader);

      await _openSheet(tester);

      expect(find.text('Tempelkan Kartu'), findsOneWidget);
      expect(reader.readCallCount, 1);
    });

    testWidgets('a valid card logs in and closes the sheet', (tester) async {
      final reader = FakeCardReaderService();
      final container = await _pump(tester, reader: reader);
      await _openSheet(tester);

      reader.tap('04A1B2C3');
      await tester.pumpAndSettle();

      expect(container.read(isLoggedInProvider), isTrue);
      expect(find.text('Tempelkan Kartu'), findsNothing);
    });

    testWidgets('an unregistered card shows the error and can retry', (
      tester,
    ) async {
      final reader = FakeCardReaderService();
      final container = await _pump(
        tester,
        reader: reader,
        statusCode: 401,
        body: _unauthorizedBody,
      );
      await _openSheet(tester);

      reader.tap('DEADBEEF');
      await tester.pumpAndSettle();

      expect(find.text('Kartu tidak terdaftar.'), findsOneWidget);
      expect(container.read(isLoggedInProvider), isFalse);

      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(reader.readCallCount, 2);
      expect(find.text('Kartu tidak terdaftar.'), findsNothing);
    });

    testWidgets('cancelling after an error leaves no stale error behind', (
      tester,
    ) async {
      final reader = FakeCardReaderService();
      await _pump(
        tester,
        reader: reader,
        statusCode: 401,
        body: _unauthorizedBody,
      );
      await _openSheet(tester);
      reader.tap('DEADBEEF');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Kartu tidak terdaftar.'), findsNothing);
    });

    testWidgets('a failed read shows its message', (tester) async {
      final reader = FakeCardReaderService();
      await _pump(tester, reader: reader);
      await _openSheet(tester);

      reader.fail('Waktu habis. Tempelkan kartu lagi.');
      await tester.pumpAndSettle();

      expect(find.text('Waktu habis. Tempelkan kartu lagi.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('Batal cancels the read and closes the sheet', (tester) async {
      final reader = FakeCardReaderService();
      await _pump(tester, reader: reader);
      await _openSheet(tester);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(reader.cancelCallCount, greaterThan(0));
      expect(find.text('Tempelkan Kartu'), findsNothing);
    });

    testWidgets('NFC switched off explains it instead of reading', (
      tester,
    ) async {
      final reader = FakeCardReaderService(
        state: CardReaderAvailability.disabled,
      );
      await _pump(tester, reader: reader);
      await _openSheet(tester);

      expect(find.textContaining('NFC belum aktif'), findsOneWidget);
      expect(reader.readCallCount, 0);
    });
  });
}

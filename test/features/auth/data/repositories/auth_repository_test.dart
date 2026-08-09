import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/canned_dio.dart';
import '../../../../support/fake_local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loginWithPassword stores the access token on success', () async {
    final storage = FakeLocalStorage();
    final repository = AuthRepository(
      dio: cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Success',
          'code': 200,
          'trace_id': 'abc',
        },
        'data': {
          'access_token': 'tok_123',
          'user': {'id': 'u1', 'username': 'budi'},
        },
      }),
      localStorage: storage,
    );

    await repository.loginWithPassword(username: 'budi', password: 'secret');

    expect(storage.values[authTokenStorageKey], 'tok_123');
  });

  test('loginWithPassword throws AuthException with fieldErrors on 422', () async {
    final storage = FakeLocalStorage();
    final repository = AuthRepository(
      dio: cannedDio(422, {
        'meta': {
          'success': false,
          'message': 'Validation',
          'code': 422,
          'trace_id': 'abc',
        },
        'errors': {
          'password': ['Password wajib diisi.'],
        },
      }),
      localStorage: storage,
    );

    await expectLater(
      repository.loginWithPassword(username: 'budi', password: ''),
      throwsA(
        isA<AuthException>()
            .having(
              (e) => e.fieldErrors,
              'fieldErrors',
              {
                'password': ['Password wajib diisi.'],
              },
            )
            .having((e) => e.message, 'message', 'Password wajib diisi.'),
      ),
    );
  });

  test('loginWithPassword throws a generic message on 401', () async {
    final storage = FakeLocalStorage();
    final repository = AuthRepository(
      dio: cannedDio(401, {
        'meta': {
          'success': false,
          'message': 'Unauthorized',
          'code': 401,
          'trace_id': 'abc',
        },
        'errors': null,
      }),
      localStorage: storage,
    );

    await expectLater(
      repository.loginWithPassword(username: 'budi', password: 'wrong'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Username atau password salah.',
        ),
      ),
    );
  });

  test('loginWithPassword throws a generic message on server error', () async {
    final storage = FakeLocalStorage();
    final repository = AuthRepository(
      dio: cannedDio(500, {
        'meta': {
          'success': false,
          'message': 'Error',
          'code': 500,
          'trace_id': 'abc',
        },
      }),
      localStorage: storage,
    );

    await expectLater(
      repository.loginWithPassword(username: 'budi', password: 'secret'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Terjadi kesalahan. Coba lagi.',
        ),
      ),
    );
  });

  test('logout clears the local session even if the API call fails', () async {
    final storage = FakeLocalStorage()..values[authTokenStorageKey] = 'tok_123';
    final repository = AuthRepository(
      dio: cannedDio(500, {
        'meta': {
          'success': false,
          'message': 'Error',
          'code': 500,
          'trace_id': 'abc',
        },
      }),
      localStorage: storage,
    );

    await repository.logout();

    expect(storage.values.containsKey(authTokenStorageKey), isFalse);
  });
}

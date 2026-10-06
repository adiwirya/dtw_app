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
    expect(storage.values[sessionUserIdStorageKey], 'u1');
    expect(storage.values.containsKey(tenantBranchIdStorageKey), isFalse);
  });

  test('loginWithPassword persists the display name when present', () async {
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
          'user': {'id': 'u1', 'username': 'budi', 'name': 'Budi Santoso'},
        },
      }),
      localStorage: storage,
    );

    await repository.loginWithPassword(username: 'budi', password: 'secret');

    expect(storage.values[sessionNameStorageKey], 'Budi Santoso');
  });

  test('loginWithPassword deletes the stored name when absent', () async {
    final storage = FakeLocalStorage()..values[sessionNameStorageKey] = 'Old';
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

    expect(storage.values.containsKey(sessionNameStorageKey), isFalse);
  });

  test('loginWithPassword persists the branch id for a branch-scoped login',
      () async {
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
          'user': {'id': 'u1', 'username': 'janji_jiwa_smlb'},
          'abilities': <dynamic>[],
          'scopes': [
            {'type': 'branch', 'tenant_branch_id': 'branch-1'},
          ],
        },
      }),
      localStorage: storage,
    );

    final response = await repository.loginWithPassword(
      username: 'janji_jiwa_smlb',
      password: 'secret',
    );

    expect(response.branchId, 'branch-1');
    expect(storage.values[tenantBranchIdStorageKey], 'branch-1');
  });

  test('loginWithPassword persists the zone id for a zone-scoped login',
      () async {
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
          'user': {'id': 'u1', 'username': 'busboy1'},
          'abilities': <dynamic>[],
          'scopes': [
            {'type': 'zone', 'zone_id': 'zone-1'},
          ],
        },
      }),
      localStorage: storage,
    );

    final response = await repository.loginWithPassword(
      username: 'busboy1',
      password: 'secret',
    );

    expect(response.zoneId, 'zone-1');
    expect(storage.values[busboyZoneIdStorageKey], 'zone-1');
    expect(storage.values.containsKey(tenantBranchIdStorageKey), isFalse);
  });

  test('loginWithPassword throws AuthException with fieldErrors on 422', () 
  async {
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
    final storage = FakeLocalStorage()
      ..values[authTokenStorageKey] = 'tok_123'
      ..values[sessionUserIdStorageKey] = 'u1';
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
    expect(storage.values.containsKey(busboyZoneIdStorageKey), isFalse);
    expect(storage.values.containsKey(sessionUserIdStorageKey), isFalse);
  });

  group('forgotPassword', () {
    test('completes without throwing on success', () async {
      final repository = AuthRepository(
        dio: cannedDio(200, {
          'meta': {
            'success': true,
            'message': 'Success',
            'code': 200,
            'trace_id': 'abc',
          },
          'data': null,
        }),
        localStorage: FakeLocalStorage(),
      );

      await repository.forgotPassword(email: 'busboy@example.com');
    });

    test('sends email in the request body', () async {
      final dio = cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Success',
          'code': 200,
          'trace_id': 'abc',
        },
        'data': null,
      });
      final repository = AuthRepository(
        dio: dio,
        localStorage: FakeLocalStorage(),
      );

      await repository.forgotPassword(email: 'busboy@example.com');

      final lastRequest = (dio.httpClientAdapter as CannedAdapter).lastRequest;
      expect(lastRequest!.path, '/v1/auth/forgot-password');
      expect(lastRequest.data, {'email': 'busboy@example.com'});
    });

    test('429 rate limit throws a mapped ApiException', () async {
      final repository = AuthRepository(
        dio: cannedDio(429, {
          'meta': {
            'success': false,
            'message': 'Too Many Attempts.',
            'code': 429,
            'trace_id': 'abc',
          },
        }),
        localStorage: FakeLocalStorage(),
      );

      await expectLater(
        repository.forgotPassword(email: 'busboy@example.com'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('resetPassword', () {
    test('sends email/token/password/password_confirmation', () async {
      final dio = cannedDio(200, {
        'meta': {
          'success': true,
          'message': 'Success',
          'code': 200,
          'trace_id': 'abc',
        },
        'data': null,
      });
      final repository = AuthRepository(
        dio: dio,
        localStorage: FakeLocalStorage(),
      );

      await repository.resetPassword(
        email: 'busboy@example.com',
        token: '123456',
        password: 'newSecret1',
        passwordConfirmation: 'newSecret1',
      );

      final lastRequest = (dio.httpClientAdapter as CannedAdapter).lastRequest;
      expect(lastRequest!.path, '/v1/auth/reset-password');
      expect(lastRequest.data, {
        'email': 'busboy@example.com',
        'token': '123456',
        'password': 'newSecret1',
        'password_confirmation': 'newSecret1',
      });
    });

    test('an invalid/expired token throws a mapped ApiException', () async {
      final repository = AuthRepository(
        dio: cannedDio(422, {
          'meta': {
            'success': false,
            'message': 'Validation',
            'code': 422,
            'trace_id': 'abc',
          },
          'errors': {
            'token': [
              'Link reset password tidak valid atau sudah kedaluwarsa.',
            ],
          },
        }),
        localStorage: FakeLocalStorage(),
      );

      await expectLater(
        repository.resetPassword(
          email: 'busboy@example.com',
          token: 'bad-token',
          password: 'newSecret1',
          passwordConfirmation: 'newSecret1',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Link reset password tidak valid atau sudah kedaluwarsa.',
          ),
        ),
      );
    });
  });

  group('loginWithCard', () {
    Map<String, Object?> okBody({String? username}) => {
          'meta': {
            'success': true,
            'message': 'Success',
            'code': 200,
            'trace_id': 'abc',
          },
          'data': {
            'access_token': 'tok_card',
            'user': {'id': 'u9', 'username': username, 'role': 'tenant_keeper'},
          },
        };

    test('posts method=card with the uid and stores the session', () async {
      final storage = FakeLocalStorage();
      final dio = cannedDio(200, okBody(username: 'budi'));
      final repository = AuthRepository(dio: dio, localStorage: storage);

      final response = await repository.loginWithCard(cardUid: '04A1B2C3');

      final request = (dio.httpClientAdapter as CannedAdapter).lastRequest!;
      expect(request.path, '/v1/auth/login');
      expect(request.data, {'method': 'card', 'card_uid': '04A1B2C3'});
      expect(response.accessToken, 'tok_card');
      expect(storage.values[authTokenStorageKey], 'tok_card');
      expect(storage.values[sessionRoleStorageKey], 'tenant_keeper');
    });

    test('keeps the role when the card user has no username', () async {
      final storage = FakeLocalStorage();
      final repository = AuthRepository(
        dio: cannedDio(200, okBody()),
        localStorage: storage,
      );

      await repository.loginWithCard(cardUid: '04A1B2C3');

      // A card-only user has no username; that must not wipe the role the
      // router needs to pick the tenant/busboy shell.
      expect(storage.values[sessionRoleStorageKey], 'tenant_keeper');
      expect(storage.values.containsKey(sessionUsernameStorageKey), isFalse);
    });

    test('maps 401 to a card-specific message', () async {
      final repository = AuthRepository(
        dio: cannedDio(401, {
          'meta': {'success': false, 'message': 'Unauthorized', 'code': 401},
          'errors': null,
        }),
        localStorage: FakeLocalStorage(),
      );

      expect(
        () => repository.loginWithCard(cardUid: 'DEADBEEF'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Kartu tidak terdaftar.',
          ),
        ),
      );
    });
  });
}

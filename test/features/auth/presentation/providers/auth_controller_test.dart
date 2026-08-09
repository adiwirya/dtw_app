import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/auth/data/repositories/auth_repository.dart';
import 'package:dtw_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/canned_dio.dart';
import '../../../../support/fake_local_storage.dart';

AuthRepository _repositoryReturning(
  int statusCode,
  Object? body,
  FakeLocalStorage storage,
) {
  return AuthRepository(dio: cannedDio(statusCode, body), localStorage: storage);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('login sets isLoggedInProvider and appFlavorProvider on success', () async {
    final storage = FakeLocalStorage();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _repositoryReturning(200, {
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
          }, storage),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .login(username: 'budi', password: 'secret');

    expect(container.read(isLoggedInProvider), isTrue);
    expect(container.read(appFlavorProvider), AppFlavor.busboy);
    expect(container.read(authControllerProvider).error, isNull);
  });

  test('login sets an error with the mapped AuthException on 401', () async {
    final storage = FakeLocalStorage();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _repositoryReturning(401, {
            'meta': {
              'success': false,
              'message': 'Unauthorized',
              'code': 401,
              'trace_id': 'abc',
            },
            'errors': null,
          }, storage),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .login(username: 'budi', password: 'wrong');

    final state = container.read(authControllerProvider);
    expect(state.error, isNotNull);
    expect((state.error! as AuthException).message, 'Username atau password salah.');
    expect(state.isLoading, isFalse);
    expect(container.read(isLoggedInProvider), isFalse);
  });

  test('logout clears isLoggedInProvider', () async {
    final storage = FakeLocalStorage()..values[authTokenStorageKey] = 'tok_123';
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _repositoryReturning(200, {
            'meta': {
              'success': true,
              'message': 'Success',
              'code': 200,
              'trace_id': 'abc',
            },
          }, storage),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(isLoggedInProvider.notifier).state = true;

    await container.read(authControllerProvider.notifier).logout();

    expect(container.read(isLoggedInProvider), isFalse);
  });
}

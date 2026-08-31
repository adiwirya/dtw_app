import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/notifications/tenant_foreground_service.dart';
import 'package:dtw_app/core/realtime/busboy_realtime_service.dart';
import 'package:dtw_app/core/realtime/tenant_realtime_service.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/auth/data/repositories/auth_repository.dart';
import 'package:dtw_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/canned_dio.dart';
import '../../../../support/fake_busboy_realtime_service.dart';
import '../../../../support/fake_local_storage.dart';
import '../../../../support/fake_tenant_foreground_service.dart';
import '../../../../support/fake_tenant_realtime_service.dart';

AuthRepository _repositoryReturning(
  int statusCode,
  Object? body,
  FakeLocalStorage storage,
) {
  return AuthRepository(dio: cannedDio(statusCode, body), 
  localStorage: storage);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('login sets isLoggedInProvider on success', () async {
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
    expect((state.error! as AuthException).message, 
    'Username atau password salah.');
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

  test('login connects the realtime service for a branch-scoped response',
      () async {
    final storage = FakeLocalStorage();
    final realtime = FakeTenantRealtimeService();
    addTearDown(realtime.close);
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
              'user': {'id': 'u1', 'username': 'janji_jiwa_smlb'},
              'abilities': <dynamic>[],
              'scopes': [
                {'type': 'branch', 'tenant_branch_id': 'branch-1'},
              ],
            },
          }, storage),
        ),
        tenantRealtimeServiceProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .login(username: 'janji_jiwa_smlb', password: 'secret');

    expect(realtime.connectCalls, [(token: 'tok_123', branchId: 'branch-1')]);
  });

  test(
      'login starts the tenant foreground service for a branch-scoped '
      'response', () async {
    final storage = FakeLocalStorage();
    final foregroundService = FakeTenantForegroundService();
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
              'user': {'id': 'u1', 'username': 'janji_jiwa_smlb'},
              'abilities': <dynamic>[],
              'scopes': [
                {'type': 'branch', 'tenant_branch_id': 'branch-1'},
              ],
            },
          }, storage),
        ),
        tenantForegroundServiceProvider.overrideWithValue(foregroundService),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .login(username: 'janji_jiwa_smlb', password: 'secret');

    expect(foregroundService.startCallCount, 1);
  });

  test(
      'login does not start the foreground service for a scope-less '
      'response', () async {
    final storage = FakeLocalStorage();
    final foregroundService = FakeTenantForegroundService();
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
        tenantForegroundServiceProvider.overrideWithValue(foregroundService),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .login(username: 'budi', password: 'secret');

    expect(foregroundService.startCallCount, 0);
  });

  test('login connects the busboy realtime service for a zone-scoped '
      'response', () async {
    final storage = FakeLocalStorage();
    final realtime = FakeBusboyRealtimeService();
    addTearDown(realtime.close);
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
              'user': {'id': 'u1', 'username': 'busboy1'},
              'abilities': <dynamic>[],
              'scopes': [
                {'type': 'zone', 'zone_id': 'zone-1'},
              ],
            },
          }, storage),
        ),
        busboyRealtimeServiceProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .login(username: 'busboy1', password: 'secret');

    expect(realtime.connectCalls, [(token: 'tok_123', zoneId: 'zone-1')]);
  });

  test('login does not connect either realtime service for a scope-less '
      'response', () async {
    final storage = FakeLocalStorage();
    final tenantRealtime = FakeTenantRealtimeService();
    addTearDown(tenantRealtime.close);
    final busboyRealtime = FakeBusboyRealtimeService();
    addTearDown(busboyRealtime.close);
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
        tenantRealtimeServiceProvider.overrideWithValue(tenantRealtime),
        busboyRealtimeServiceProvider.overrideWithValue(busboyRealtime),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .login(username: 'budi', password: 'secret');

    expect(tenantRealtime.connectCalls, isEmpty);
    expect(busboyRealtime.connectCalls, isEmpty);
  });

  // Reverb only drives live order-status updates on the tenant order board —
  // it is not part of the login contract. A broken/unreachable realtime
  // endpoint (confirmed against the real Downtown CMS server: neither the
  // assumed port 443 nor 8080 completes a WebSocket handshake from outside)
  // must never block or fail login; `connect()` is fire-and-forget.
  test(
      'login logs the user in even when the realtime connect fails for a '
      'branch-scoped response (best-effort, non-blocking)', () async {
    final storage = FakeLocalStorage();
    final realtime = FakeTenantRealtimeService()
      ..connectError = Exception('socket unreachable');
    addTearDown(realtime.close);
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
              'user': {'id': 'u1', 'username': 'janji_jiwa_smlb'},
              'abilities': <dynamic>[],
              'scopes': [
                {'type': 'branch', 'tenant_branch_id': 'branch-1'},
              ],
            },
          }, storage),
        ),
        tenantRealtimeServiceProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .login(username: 'janji_jiwa_smlb', password: 'secret');

    expect(container.read(isLoggedInProvider), isTrue);
    expect(container.read(authControllerProvider).error, isNull);
    expect(realtime.connectCalls, [(token: 'tok_123', branchId: 'branch-1')]);
  });

  test('login sets sessionZoneIdProvider for a zone-scoped response',
      () async {
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
              'user': {'id': 'u1', 'username': 'busboy1'},
              'abilities': <dynamic>[],
              'scopes': [
                {'type': 'zone', 'zone_id': 'zone-1'},
              ],
            },
          }, storage),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .login(username: 'busboy1', password: 'secret');

    expect(container.read(sessionZoneIdProvider), 'zone-1');
    expect(container.read(sessionBranchIdProvider), isNull);
  });

  test('login sets sessionUsernameProvider from data.user.username',
      () async {
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
              'user': {'id': 'u1', 'username': 'busboy1'},
            },
          }, storage),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .login(username: 'busboy1', password: 'secret');

    expect(container.read(sessionUsernameProvider), 'busboy1');
    // Persisted so a relaunched session can still greet the user.
    expect(storage.values[sessionUsernameStorageKey], 'busboy1');
  });

  test('login sets and persists sessionRoleProvider', () async {
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
              'user': {
                'id': 'u1',
                'username': 'janji_jiwa_smlb',
                'role': 'tenant_keeper',
              },
              'abilities': <dynamic>[],
              'scopes': [
                {'type': 'branch', 'tenant_branch_id': 'branch-1'},
              ],
            },
          }, storage),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .login(username: 'janji_jiwa_smlb', password: 'secret');

    expect(container.read(sessionRoleProvider), 'tenant_keeper');
    // Persisted so a relaunched session resumes on the same shell.
    expect(storage.values[sessionRoleStorageKey], 'tenant_keeper');
  });

  test('logout clears sessionRoleProvider and its stored value', () async {
    final storage = FakeLocalStorage()
      ..values[authTokenStorageKey] = 'tok_123'
      ..values[sessionRoleStorageKey] = 'tenant_keeper';
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
    container.read(sessionRoleProvider.notifier).state = 'tenant_keeper';

    await container.read(authControllerProvider.notifier).logout();

    expect(container.read(sessionRoleProvider), isNull);
    expect(storage.values.containsKey(sessionRoleStorageKey), isFalse);
  });

  test('logout clears sessionUsernameProvider and its stored value', () async {
    final storage = FakeLocalStorage()
      ..values[authTokenStorageKey] = 'tok_123'
      ..values[sessionUsernameStorageKey] = 'busboy1';
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
    container.read(sessionUsernameProvider.notifier).state = 'busboy1';

    await container.read(authControllerProvider.notifier).logout();

    expect(container.read(sessionUsernameProvider), isNull);
    expect(storage.values.containsKey(sessionUsernameStorageKey), isFalse);
  });

  test('logout clears sessionZoneIdProvider', () async {
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
    container.read(sessionZoneIdProvider.notifier).state = 'zone-1';

    await container.read(authControllerProvider.notifier).logout();

    expect(container.read(sessionZoneIdProvider), isNull);
  });

  test('logout disconnects the realtime service', () async {
    final storage = FakeLocalStorage()..values[authTokenStorageKey] = 'tok_123';
    final realtime = FakeTenantRealtimeService();
    addTearDown(realtime.close);
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
        tenantRealtimeServiceProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).logout();

    expect(realtime.disconnectCallCount, 1);
  });

  test('logout stops the tenant foreground service', () async {
    final storage = FakeLocalStorage()..values[authTokenStorageKey] = 'tok_123';
    final foregroundService = FakeTenantForegroundService();
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
        tenantForegroundServiceProvider.overrideWithValue(foregroundService),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).logout();

    expect(foregroundService.stopCallCount, 1);
  });

  test('logout disconnects the busboy realtime service', () async {
    final storage = FakeLocalStorage()..values[authTokenStorageKey] = 'tok_123';
    final realtime = FakeBusboyRealtimeService();
    addTearDown(realtime.close);
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
        busboyRealtimeServiceProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).logout();

    expect(realtime.disconnectCallCount, 1);
  });
}

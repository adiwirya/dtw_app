import 'package:dtw_app/features/auth/data/models/login_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LoginResponse.fromJson parses the envelope data field', () {
    final json = {
      'meta': {
        'success': true,
        'message': 'Success',
        'code': 200,
        'trace_id': 'abc',
      },
      'data': {
        'access_token': 'tok_123',
        'user': {'id': 'u1', 'username': 'budi'},
        'abilities': <dynamic>[],
        'scopes': <dynamic>[],
      },
    };

    final result = LoginResponse.fromJson(json);

    expect(result.accessToken, 'tok_123');
    expect(result.user.id, 'u1');
    expect(result.user.username, 'budi');
  });

  test('LoginResponse.fromJson extracts branchId from a branch-typed scope',
      () {
    final json = {
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
    };

    final result = LoginResponse.fromJson(json);

    expect(result.branchId, 'branch-1');
  });

  test('LoginResponse.fromJson leaves branchId null with no branch scope',
      () {
    final json = {
      'meta': {
        'success': true,
        'message': 'Success',
        'code': 200,
        'trace_id': 'abc',
      },
      'data': {
        'access_token': 'tok_123',
        'user': {'id': 'u1', 'username': 'budi'},
        'abilities': <dynamic>[],
        'scopes': <dynamic>[],
      },
    };

    final result = LoginResponse.fromJson(json);

    expect(result.branchId, isNull);
  });
}

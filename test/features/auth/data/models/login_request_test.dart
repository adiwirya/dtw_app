import 'package:dtw_app/features/auth/data/models/login_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'LoginRequest.password.toJson sends method/username/password',
    () {
      final request = LoginRequest.password(
        username: 'budi',
        password: 'secret',
      );

      expect(request.toJson(), {
        'method': 'password',
        'username': 'budi',
        'password': 'secret',
      });
    },
  );

  test('LoginRequest.card.toJson sends only method/card_uid', () {
    expect(LoginRequest.card(cardUid: '04A1B2C3D4E5F6').toJson(), {
      'method': 'card',
      'card_uid': '04A1B2C3D4E5F6',
    });
  });
}

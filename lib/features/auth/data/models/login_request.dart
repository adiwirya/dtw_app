class LoginRequest {
  const LoginRequest._({
    required this.method,
    this.username,
    this.password,
    this.cardUid,
  });

  factory LoginRequest.password({
    required String username,
    required String password,
  }) {
    return LoginRequest._(
      method: 'password',
      username: username,
      password: password,
    );
  }

  /// NFC tap-login — [cardUid] is the tag's UID as upper-case hex with no
  /// separators (what `flutter_nfc_kit` reports as `tag.id`).
  factory LoginRequest.card({required String cardUid}) =>
      LoginRequest._(method: 'card', cardUid: cardUid);

  final String method;
  final String? username;
  final String? password;
  final String? cardUid;

  Map<String, dynamic> toJson() => {
    'method': method,
    if (username != null) 'username': username,
    if (password != null) 'password': password,
    if (cardUid != null) 'card_uid': cardUid,
  };
}

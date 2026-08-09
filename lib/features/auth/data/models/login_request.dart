class LoginRequest {
  const LoginRequest._({required this.method, this.username, this.password});

  factory LoginRequest.password({
    required String username,
    required String password,
  }) {
    return LoginRequest._(method: 'password', username: username, password: password);
  }

  final String method;
  final String? username;
  final String? password;

  Map<String, dynamic> toJson() => {
        'method': method,
        if (username != null) 'username': username,
        if (password != null) 'password': password,
      };
}

class AuthUser {
  const AuthUser({required this.id, this.username});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      username: json['username'] as String?,
    );
  }

  final String id;
  final String? username;
}

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.user,
    this.branchId,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return LoginResponse(
      accessToken: data['access_token'] as String,
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      branchId: _branchIdFromScopes(data['scopes']),
    );
  }

  final String accessToken;
  final AuthUser user;

  /// The tenant branch this session is scoped to, taken from the
  /// `scopes` entry whose `type` is `"branch"` — confirmed live against the
  /// Downtown CMS API: this value is **not** present on `data.user`.
  /// `null` for a session with no branch scope (a plain busboy/staff login).
  final String? branchId;

  static String? _branchIdFromScopes(Object? scopes) {
    if (scopes is! List) return null;
    for (final scope in scopes) {
      if (scope is Map && scope['type'] == 'branch') {
        return scope['tenant_branch_id'] as String?;
      }
    }
    return null;
  }
}

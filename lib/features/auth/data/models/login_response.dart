class AuthUser {
  const AuthUser({required this.id, this.username, this.email, this.role});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      username: json['username'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
    );
  }

  final String id;
  final String? username;
  final String? email;

  /// A descriptive label (e.g. `tenant_keeper`) — confirmed live on
  /// `data.user`, not documented in the cached API reference. Not used for
  /// branch/zone routing: [LoginResponse.branchId]/[LoginResponse.zoneId]
  /// (from `scopes`) are the actual signal every branch/zone-scoped call
  /// keys off.
  final String? role;
}

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.user,
    this.branchId,
    this.zoneId,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return LoginResponse(
      accessToken: data['access_token'] as String,
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      branchId: _scopeValue(
        data['scopes'],
        type: 'branch',
        key: 'tenant_branch_id',
      ),
      zoneId: _scopeValue(data['scopes'], type: 'zone', key: 'zone_id'),
    );
  }

  final String accessToken;
  final AuthUser user;

  /// The tenant branch this session is scoped to, taken from the
  /// `scopes` entry whose `type` is `"branch"` — confirmed live against the
  /// Downtown CMS API: this value is **not** present on `data.user`.
  /// `null` for a session with no branch scope (a plain busboy/staff login).
  final String? branchId;

  /// The zone this session is scoped to, taken from the `scopes` entry whose
  /// `type` is `"zone"` — a busboy login. `null` for a session with no zone
  /// scope (e.g. a branch-scoped tenant login).
  final String? zoneId;

  static String? _scopeValue(
    Object? scopes, {
    required String type,
    required String key,
  }) {
    if (scopes is! List) return null;
    for (final scope in scopes) {
      if (scope is Map && scope['type'] == type) {
        return scope[key] as String?;
      }
    }
    return null;
  }
}

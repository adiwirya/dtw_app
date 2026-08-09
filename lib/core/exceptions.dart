class AuthException implements Exception {
  AuthException({required this.message, this.fieldErrors});

  final String message;
  final Map<String, List<String>>? fieldErrors;

  @override
  String toString() => 'AuthException: $message';
}

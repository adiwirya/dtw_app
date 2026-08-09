import 'package:dtw_app/core/storage/local_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_local_storage.g.dart';

/// Key the access token is stored under, shared between [SecureLocalStorage]
/// consumers: the login/logout flow (`AuthRepository`) and the request/error
/// interceptors in `dioProvider`.
const authTokenStorageKey = 'auth_token';

/// [LocalStorage] backed by the platform Keychain (iOS) / EncryptedShared
/// Preferences+Keystore (Android) via `flutter_secure_storage`.
class SecureLocalStorage implements LocalStorage {
  const SecureLocalStorage({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

@riverpod
LocalStorage localStorage(Ref ref) => const SecureLocalStorage();

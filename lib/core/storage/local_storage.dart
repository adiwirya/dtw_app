/// Contract for local key-value persistence. Implement against a concrete
/// backend (e.g. shared_preferences, flutter_secure_storage) as the app
/// grows past its bootstrap state.
abstract class LocalStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

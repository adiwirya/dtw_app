import 'package:dtw_app/core/storage/local_storage.dart';

/// In-memory [LocalStorage] test double — no platform channel involved.
class FakeLocalStorage implements LocalStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

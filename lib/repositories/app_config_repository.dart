import '../database/database.dart';

class AppConfigRepository {
  final AppDatabase _db;

  AppConfigRepository(this._db);

  Future<String?> getValue(String key) async {
    final row = await (_db.select(_db.appConfig)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setValue(String key, String value) async {
    await _db.into(_db.appConfig).insertOnConflictUpdate(
          AppConfigCompanion.insert(key: key, value: value),
        );
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final value = await getValue(key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  Future<int> getInt(String key, {int defaultValue = 0}) async {
    final value = await getValue(key);
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  Future<void> setBool(String key, bool value) =>
      setValue(key, value.toString());

  Future<void> setInt(String key, int value) =>
      setValue(key, value.toString());
}

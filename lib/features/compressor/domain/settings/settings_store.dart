import 'settings_models.dart';

/// Persistence and data-management port for user settings.
abstract interface class SettingsStore {
  Future<SettingsPreferences> load();
  Future<SettingsStorageUsage> loadStorageUsage();
  Future<void> save(SettingsPreferences preferences);
  Future<void> clearCache();
  Future<void> clearHistory();
  Future<String> export(SettingsExportBundle bundle);
  Future<void> importSettings(String encoded);
}

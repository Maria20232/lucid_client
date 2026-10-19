import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStore {
  Future<String?> read();
  Future<void> write(String data);
}

class PreferencesStore implements LocalStore {
  static const key = 'lucid.client.state.v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  @override
  Future<String?> read() => _preferences.getString(key);
  @override
  Future<void> write(String data) => _preferences.setString(key, data);
}

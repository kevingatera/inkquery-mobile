import 'package:shared_preferences/shared_preferences.dart';

class ScopedPrefsStore {
  const ScopedPrefsStore();

  String _scopedKey(String scopeKey, String key) => '$scopeKey:$key';

  Future<String?> getString(String scopeKey, String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_scopedKey(scopeKey, key));
  }

  Future<void> setString(String scopeKey, String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scopedKey(scopeKey, key), value);
  }
}

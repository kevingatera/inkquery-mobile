import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_models.dart';

class SecureTokenStore {
  SecureTokenStore()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _storage;

  String _keyForScope(String scopeKey) => 'session:$scopeKey';

  Future<SessionTokens?> readTokens(String scopeKey) async {
    final raw = await _storage.read(key: _keyForScope(scopeKey));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return SessionTokens.decode(raw);
  }

  Future<void> writeTokens(String scopeKey, SessionTokens tokens) async {
    await _storage.write(key: _keyForScope(scopeKey), value: tokens.encode());
  }

  Future<void> deleteTokens(String scopeKey) async {
    await _storage.delete(key: _keyForScope(scopeKey));
  }
}

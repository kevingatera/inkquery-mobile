import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_models.dart';

class AccountStore {
  static const _accountsKey = 'saved_accounts';
  static const _activeScopeKey = 'active_account_scope';

  Future<List<SavedAccount>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    final accounts = decoded
        .map((item) => SavedAccount.fromJson(item as Map<String, dynamic>))
        .toList();
    accounts.sort((left, right) => right.lastUsedAt.compareTo(left.lastUsedAt));
    return accounts;
  }

  Future<String?> loadActiveScope() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeScopeKey);
  }

  Future<void> saveAccount(SavedAccount account) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await loadAccounts()
      ..removeWhere((item) => item.scopeKey == account.scopeKey)
      ..insert(0, account);

    await prefs.setString(
      _accountsKey,
      jsonEncode(accounts.map((item) => item.toJson()).toList()),
    );
    await prefs.setString(_activeScopeKey, account.scopeKey);
  }

  Future<void> setActiveScope(String scopeKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeScopeKey, scopeKey);
  }

  Future<void> clearActiveScope() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeScopeKey);
  }

  Future<void> removeAccount(String scopeKey) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts =
        (await loadAccounts())..removeWhere((item) => item.scopeKey == scopeKey);

    await prefs.setString(
      _accountsKey,
      jsonEncode(accounts.map((item) => item.toJson()).toList()),
    );

    final activeScope = prefs.getString(_activeScopeKey);
    if (activeScope == scopeKey) {
      if (accounts.isEmpty) {
        await prefs.remove(_activeScopeKey);
      } else {
        await prefs.setString(_activeScopeKey, accounts.first.scopeKey);
      }
    }
  }
}

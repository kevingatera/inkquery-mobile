import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../services/account_store.dart';
import '../services/inkquery_api_client.dart';
import '../services/secure_token_store.dart';

enum AuthStatus { starting, signedOut, signingIn, ready }

class AuthController extends ChangeNotifier {
  AuthController({
    required InkqueryApiClient apiClient,
    required AccountStore accountStore,
    required SecureTokenStore tokenStore,
  })  : _apiClient = apiClient,
        _accountStore = accountStore,
        _tokenStore = tokenStore;

  static const defaultServerUrl = 'http://192.168.1.108:8420';

  final InkqueryApiClient _apiClient;
  final AccountStore _accountStore;
  final SecureTokenStore _tokenStore;

  AuthStatus _status = AuthStatus.starting;
  AuthSession? _session;
  List<SavedAccount> _accounts = const [];
  ServerCapabilities? _capabilities;
  String? _errorMessage;

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  List<SavedAccount> get accounts => List.unmodifiable(_accounts);
  SavedAccount? get activeAccount => _session?.account;
  String? get activeScopeKey => _session?.account.scopeKey;
  String? get errorMessage => _errorMessage;
  ServerCapabilities? get capabilities => _capabilities;
  bool get isBusy => _status == AuthStatus.starting || _status == AuthStatus.signingIn;
  bool get isAuthenticated => _status == AuthStatus.ready && _session != null;

  String get suggestedServerUrl {
    if (_accounts.isNotEmpty) {
      return _accounts.first.serverUrl;
    }
    return defaultServerUrl;
  }

  Future<void> initialize() async {
    _status = AuthStatus.starting;
    _errorMessage = null;
    notifyListeners();

    _accounts = await _accountStore.loadAccounts();
    final activeScope = await _accountStore.loadActiveScope();
    if (activeScope == null) {
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }

    final active = _findAccount(activeScope);
    if (active == null) {
      await _accountStore.clearActiveScope();
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }

    await _restoreAccount(active);
  }

  Future<void> inspectServer(String rawServerUrl) async {
    try {
      final serverUrl = normalizeServerUrl(rawServerUrl);
      _capabilities = await _apiClient.getCapabilities(serverUrl);
      _errorMessage = null;
    } on FormatException catch (error) {
      _errorMessage = error.message;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Could not inspect the server.';
    }
    notifyListeners();
  }

  Future<bool> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    _status = AuthStatus.signingIn;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedServerUrl = normalizeServerUrl(serverUrl);
      await _apiClient.pingHealth(normalizedServerUrl);
      _capabilities = await _apiClient.getCapabilities(normalizedServerUrl);

      if (_capabilities?.localEnabled == false) {
        throw const ApiException(
          statusCode: 400,
          message: 'This server does not allow local username/password sign-in.',
        );
      }

      final envelope = await _apiClient.loginLocal(
        baseUrl: normalizedServerUrl,
        username: username,
        password: password,
      );

      final account = SavedAccount.create(
        serverUrl: normalizedServerUrl,
        username: envelope.user.username,
        userId: envelope.user.id,
        role: envelope.user.role,
      );

      await _setSession(
        AuthSession(account: account, tokens: envelope.tokens, user: envelope.user),
      );

      return true;
    } on FormatException catch (error) {
      _errorMessage = error.message;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Sign-in failed. Check the server URL and try again.';
    }

    _status = AuthStatus.signedOut;
    notifyListeners();
    return false;
  }

  Future<bool> switchAccount(String scopeKey) async {
    final account = _findAccount(scopeKey);
    if (account == null) {
      return false;
    }
    await _accountStore.setActiveScope(scopeKey);
    return _restoreAccount(account);
  }

  Future<void> removeAccount(String scopeKey) async {
    await _tokenStore.deleteTokens(scopeKey);
    await _accountStore.removeAccount(scopeKey);
    _accounts = await _accountStore.loadAccounts();

    if (_session?.account.scopeKey == scopeKey) {
      _session = null;
      final nextAccount = _accounts.isEmpty ? null : _accounts.first;
      if (nextAccount != null) {
        await _restoreAccount(nextAccount);
        return;
      }
      _status = AuthStatus.signedOut;
    }

    notifyListeners();
  }

  Future<void> logoutCurrent() async {
    final current = _session;
    if (current != null) {
      try {
        await _apiClient.logout(
          baseUrl: current.account.serverUrl,
          refreshToken: current.tokens.refreshToken,
        );
      } catch (_) {}
      await _tokenStore.deleteTokens(current.account.scopeKey);
      await _accountStore.removeAccount(current.account.scopeKey);
    }

    _session = null;
    _accounts = await _accountStore.loadAccounts();
    _capabilities = null;
    _errorMessage = null;

    final nextAccount = _accounts.isEmpty ? null : _accounts.first;
    if (nextAccount != null) {
      await _restoreAccount(nextAccount);
      return;
    }

    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<AuthSession> refreshActiveSession() async {
    final current = _session;
    if (current == null) {
      throw const ApiException(statusCode: 401, message: 'Not signed in.');
    }

    final envelope = await _apiClient.refreshSession(
      baseUrl: current.account.serverUrl,
      refreshToken: current.tokens.refreshToken,
    );

    final refreshedAccount = current.account.copyWith(
      userId: envelope.user.id,
      role: envelope.user.role,
      lastUsedAt: DateTime.now(),
    );
    final refreshedSession = AuthSession(
      account: refreshedAccount,
      tokens: envelope.tokens,
      user: envelope.user,
    );
    await _setSession(refreshedSession);
    return refreshedSession;
  }

  Future<T> authorizedRequest<T>(Future<T> Function(AuthSession session) operation) async {
    final current = _session;
    if (current == null) {
      throw const ApiException(statusCode: 401, message: 'Not signed in.');
    }

    try {
      return await operation(current);
    } on ApiException catch (error) {
      if (error.statusCode != 401) {
        rethrow;
      }
      final refreshed = await refreshActiveSession();
      return operation(refreshed);
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _restoreAccount(SavedAccount account) async {
    _status = AuthStatus.starting;
    _errorMessage = null;
    notifyListeners();

    try {
      final tokens = await _tokenStore.readTokens(account.scopeKey);
      if (tokens == null) {
        throw const ApiException(
          statusCode: 401,
          message: 'Saved account is missing secure tokens. Sign in again.',
        );
      }

      UserProfile user;
      try {
        user = await _apiClient.getMe(
          baseUrl: account.serverUrl,
          accessToken: tokens.accessToken,
        );
      } on ApiException catch (error) {
        if (error.statusCode != 401) {
          rethrow;
        }
        final envelope = await _apiClient.refreshSession(
          baseUrl: account.serverUrl,
          refreshToken: tokens.refreshToken,
        );
        final refreshedAccount = account.copyWith(
          userId: envelope.user.id,
          role: envelope.user.role,
          lastUsedAt: DateTime.now(),
        );
        await _setSession(
          AuthSession(
            account: refreshedAccount,
            tokens: envelope.tokens,
            user: envelope.user,
          ),
        );
        return true;
      }

      await _setSession(
        AuthSession(
          account: account.copyWith(
            userId: user.id,
            role: user.role,
            lastUsedAt: DateTime.now(),
          ),
          tokens: tokens,
          user: user,
        ),
      );
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Could not restore the saved session.';
    }

    _session = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
    return false;
  }

  Future<void> _setSession(AuthSession session) async {
    _session = session;
    _status = AuthStatus.ready;
    _errorMessage = null;
    await _tokenStore.writeTokens(session.account.scopeKey, session.tokens);
    await _accountStore.saveAccount(session.account);
    _accounts = await _accountStore.loadAccounts();
    notifyListeners();
  }

  SavedAccount? _findAccount(String scopeKey) {
    for (final account in _accounts) {
      if (account.scopeKey == scopeKey) {
        return account;
      }
    }
    return null;
  }
}

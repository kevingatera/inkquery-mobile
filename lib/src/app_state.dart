import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'models.dart';
import 'token_storage.dart';

class InkqueryAppState extends ChangeNotifier {
  InkqueryAppState._({
    required InkqueryApiClient apiClient,
    required SharedPreferences preferences,
    required TokenStorage tokenStorage,
    required String serverUrl,
  })  : _apiClient = apiClient,
        _preferences = preferences,
        _tokenStorage = tokenStorage,
        _serverUrl = serverUrl;

  static const defaultServerUrl = 'http://192.168.1.108:8420';
  static const _serverUrlKey = 'server_url';
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _oidcCallbackScheme = 'inkquerymobile';

  final InkqueryApiClient _apiClient;
  final SharedPreferences _preferences;
  final TokenStorage _tokenStorage;

  String _serverUrl;
  AuthCapabilities? _capabilities;
  CurrentUser? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  List<BookItem> _books = const [];
  List<EntityItem> _entities = const [];
  List<ChatExchange> _chatHistory = const [];
  String _chatDraftAnswer = '';
  String _chatStage = '';
  String? _errorMessage;
  bool _initializing = true;
  bool _busy = false;
  bool _chatBusy = false;

  String get serverUrl => _serverUrl;
  AuthCapabilities? get capabilities => _capabilities;
  CurrentUser? get currentUser => _currentUser;
  List<BookItem> get books => _books;
  List<EntityItem> get entities => _entities;
  List<ChatExchange> get chatHistory => _chatHistory;
  String get chatDraftAnswer => _chatDraftAnswer;
  String get chatStage => _chatStage;
  String? get errorMessage => _errorMessage;
  bool get initializing => _initializing;
  bool get busy => _busy;
  bool get chatBusy => _chatBusy;
  bool get requiresLogin => (_capabilities?.authRequired ?? false) && _currentUser == null;

  static Future<InkqueryAppState> bootstrap({
    required InkqueryApiClient apiClient,
    required SharedPreferences preferences,
    required TokenStorage tokenStorage,
  }) async {
    final serverUrl = preferences.getString(_serverUrlKey) ?? defaultServerUrl;
    final state = InkqueryAppState._(
      apiClient: apiClient,
      preferences: preferences,
      tokenStorage: tokenStorage,
      serverUrl: serverUrl,
    );
    await state.initialize();
    return state;
  }

  Future<void> initialize() async {
    _initializing = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _capabilities = await _apiClient.getAuthCapabilities(_serverUrl);
      _accessToken = await _tokenStorage.read(_accessTokenKey);
      _refreshToken = await _tokenStorage.read(_refreshTokenKey);

      if (_capabilities!.authRequired) {
        if (_accessToken != null) {
          try {
            _currentUser = await _apiClient.getMe(
              baseUrl: _serverUrl,
              accessToken: _accessToken!,
            );
          } on InkqueryApiException catch (error) {
            if (error.statusCode == 401) {
              await _attemptRefresh();
            } else {
              rethrow;
            }
          }
        } else if (_refreshToken != null) {
          await _attemptRefresh();
        }
      }

      if (!_capabilities!.authRequired || _currentUser != null) {
        await refreshData();
      }
    } catch (error) {
      _errorMessage = _friendlyError(error, fallback: 'Unable to reach Inkquery.');
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  Future<void> updateServerUrl(String value) async {
    final next = value.trim();
    if (next.isEmpty || next == _serverUrl) {
      return;
    }
    _serverUrl = next;
    await _preferences.setString(_serverUrlKey, _serverUrl);
    await clearSession(clearServer: false);
    await initialize();
  }

  Future<void> login(String username, String password) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final session = await _apiClient.login(
        baseUrl: _serverUrl,
        username: username.trim(),
        password: password,
      );
      await _storeSession(session);
      await refreshData();
    } catch (error) {
      _errorMessage = _friendlyError(error, fallback: 'Sign-in failed.');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> loginWithOidc() async {
    if (_capabilities?.oidcEnabled != true) {
      return;
    }

    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      const callbackUri = 'inkquerymobile://auth/callback';
      final result = await FlutterWebAuth2.authenticate(
        url: _apiClient
            .buildOidcStartUri(baseUrl: _serverUrl, redirectUri: callbackUri)
            .toString(),
        callbackUrlScheme: _oidcCallbackScheme,
      );
      final returnedUri = Uri.parse(result);
      final code = returnedUri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        throw InkqueryApiException(400, 'OIDC login did not return a mobile exchange code.');
      }
      final session = await _apiClient.exchangeMobileCode(
        baseUrl: _serverUrl,
        code: code,
      );
      await _storeSession(session);
      await refreshData();
    } catch (error) {
      _errorMessage = _friendlyError(error, fallback: 'OpenID sign-in failed.');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    final accessToken = _accessToken;
    if ((_capabilities?.authRequired ?? false) && (accessToken == null || _currentUser == null)) {
      return;
    }

    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final token = accessToken ?? '';
      _books = await _apiClient.getBooks(baseUrl: _serverUrl, accessToken: token);
      _entities = await _apiClient.getEntities(baseUrl: _serverUrl, accessToken: token);
    } catch (error) {
      if (error is InkqueryApiException && error.statusCode == 401) {
        await clearSession(clearServer: false);
      }
      _errorMessage = _friendlyError(error, fallback: 'Unable to refresh mobile data.');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> askOracle(String question) async {
    final accessToken = _accessToken ?? '';
    if ((_capabilities?.authRequired ?? false) && accessToken.isEmpty) {
      return;
    }
    if (question.trim().isEmpty) {
      return;
    }

    _chatBusy = true;
    _chatStage = 'retrieving';
    _chatDraftAnswer = '';
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.streamChat(
        baseUrl: _serverUrl,
        accessToken: accessToken,
        message: question.trim(),
        onStage: (stage) {
          _chatStage = stage;
          notifyListeners();
        },
        onAnswerDelta: (delta) {
          _chatDraftAnswer += delta;
          notifyListeners();
        },
      );

      _chatHistory = [
        ChatExchange(
          question: question.trim(),
          answer: response.answer,
          responseMode: response.responseMode,
          citations: response.citations,
        ),
        ..._chatHistory,
      ];
      _chatDraftAnswer = response.answer;
      _chatStage = response.responseMode;
    } catch (error) {
      _errorMessage = _friendlyError(error, fallback: 'Oracle request failed.');
    } finally {
      _chatBusy = false;
      notifyListeners();
    }
  }

  Future<BookDetail> loadBookDetail(int bookId) async {
    return _apiClient.getBookDetail(
      baseUrl: _serverUrl,
      accessToken: _accessToken ?? '',
      bookId: bookId,
    );
  }

  Future<EntityDetail> loadEntityDetail(int entityId) async {
    return _apiClient.getEntityDetail(
      baseUrl: _serverUrl,
      accessToken: _accessToken ?? '',
      entityId: entityId,
    );
  }

  Future<void> logout() async {
    await clearSession(clearServer: false);
    _chatHistory = const [];
    _chatDraftAnswer = '';
    _chatStage = '';
    notifyListeners();
  }

  Future<void> clearSession({required bool clearServer}) async {
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    _books = const [];
    _entities = const [];
    if (clearServer) {
      _serverUrl = defaultServerUrl;
      await _preferences.remove(_serverUrlKey);
    }
    await _tokenStorage.delete(_accessTokenKey);
    await _tokenStorage.delete(_refreshTokenKey);
  }

  Future<void> _attemptRefresh() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null) {
      return;
    }
    final session = await _apiClient.refresh(
      baseUrl: _serverUrl,
      refreshToken: refreshToken,
    );
    await _storeSession(session);
  }

  Future<void> _storeSession(AuthSession session) async {
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
    _currentUser = session.user;
    await _tokenStorage.write(_accessTokenKey, session.accessToken);
    await _tokenStorage.write(_refreshTokenKey, session.refreshToken);
  }

  String _friendlyError(Object error, {required String fallback}) {
    if (error is InkqueryApiException) {
      return error.message;
    }
    return fallback;
  }
}

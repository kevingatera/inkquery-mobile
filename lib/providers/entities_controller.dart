import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/entity_models.dart';
import '../services/inkquery_api_client.dart';
import '../services/scoped_prefs_store.dart';
import 'auth_controller.dart';

class EntitiesController extends ChangeNotifier {
  EntitiesController({
    required InkqueryApiClient apiClient,
    required ScopedPrefsStore scopedPrefs,
  })  : _apiClient = apiClient,
        _scopedPrefs = scopedPrefs;

  static const _queryKey = 'entities_query';
  static const _kindKey = 'entities_kind';

  final InkqueryApiClient _apiClient;
  final ScopedPrefsStore _scopedPrefs;

  AuthController? _auth;
  String? _boundScope;
  List<EntitySummary> _items = const [];
  String _query = '';
  String _selectedKind = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<EntitySummary> get items => List.unmodifiable(_items);
  String get query => _query;
  String get selectedKind => _selectedKind;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<String> get kinds {
    final values = {
      for (final item in _items)
        if (item.kind.trim().isNotEmpty) item.kind.trim(),
    }.toList()
      ..sort();
    return values;
  }

  void bindAuth(AuthController auth) {
    _auth = auth;
    final nextScope = auth.activeScopeKey;
    if (_boundScope == nextScope) {
      return;
    }

    _boundScope = nextScope;
    _items = const [];
    _query = '';
    _selectedKind = '';
    _errorMessage = null;
    notifyListeners();

    if (nextScope != null) {
      unawaited(_restoreAndLoad(nextScope));
    }
  }

  Future<void> setQuery(String value) async {
    _query = value;
    notifyListeners();
    final scope = _boundScope;
    if (scope != null) {
      await _scopedPrefs.setString(scope, _queryKey, value);
    }
  }

  Future<void> setKind(String value) async {
    _selectedKind = value;
    notifyListeners();
    final scope = _boundScope;
    if (scope != null) {
      await _scopedPrefs.setString(scope, _kindKey, value);
    }
    await loadEntities();
  }

  Future<void> loadEntities() async {
    final auth = _auth;
    if (auth == null || !auth.isAuthenticated) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await auth.authorizedRequest(
        (session) => _apiClient.getEntities(
          baseUrl: session.account.serverUrl,
          accessToken: session.tokens.accessToken,
          query: _query,
          kind: _selectedKind,
        ),
      );
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _restoreAndLoad(String scope) async {
    _query = await _scopedPrefs.getString(scope, _queryKey) ?? '';
    _selectedKind = await _scopedPrefs.getString(scope, _kindKey) ?? '';
    notifyListeners();
    await loadEntities();
  }
}

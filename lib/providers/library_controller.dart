import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/library_models.dart';
import '../services/inkquery_api_client.dart';
import '../services/scoped_prefs_store.dart';
import 'auth_controller.dart';

class LibraryController extends ChangeNotifier {
  LibraryController({
    required InkqueryApiClient apiClient,
    required ScopedPrefsStore scopedPrefs,
  })  : _apiClient = apiClient,
        _scopedPrefs = scopedPrefs;

  static const _filterKey = 'library_filter';

  final InkqueryApiClient _apiClient;
  final ScopedPrefsStore _scopedPrefs;

  AuthController? _auth;
  String? _boundScope;
  List<BookListItem> _items = const [];
  String _filter = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<BookListItem> get items => List.unmodifiable(_items);
  String get filter => _filter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<BookListItem> get filteredItems {
    if (_filter.trim().isEmpty) {
      return _items;
    }
    final needle = _filter.toLowerCase();
    return _items.where((item) {
      return item.title.toLowerCase().contains(needle) ||
          (item.authorName ?? '').toLowerCase().contains(needle) ||
          (item.seriesName ?? '').toLowerCase().contains(needle);
    }).toList();
  }

  void bindAuth(AuthController auth) {
    _auth = auth;
    final nextScope = auth.activeScopeKey;
    if (_boundScope == nextScope) {
      return;
    }

    _boundScope = nextScope;
    _items = const [];
    _filter = '';
    _errorMessage = null;
    notifyListeners();

    if (nextScope != null) {
      unawaited(_restoreAndLoad(nextScope));
    }
  }

  Future<void> setFilter(String value) async {
    _filter = value;
    notifyListeners();
    final scope = _boundScope;
    if (scope != null) {
      await _scopedPrefs.setString(scope, _filterKey, value);
    }
  }

  Future<void> loadBooks() async {
    final auth = _auth;
    if (auth == null || !auth.isAuthenticated) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await auth.authorizedRequest(
        (session) => _apiClient.getBooks(
          baseUrl: session.account.serverUrl,
          accessToken: session.tokens.accessToken,
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
    _filter = await _scopedPrefs.getString(scope, _filterKey) ?? '';
    notifyListeners();
    await loadBooks();
  }
}

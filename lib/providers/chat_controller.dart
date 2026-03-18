import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat_models.dart';
import '../services/inkquery_api_client.dart';
import '../services/scoped_prefs_store.dart';
import 'auth_controller.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    required InkqueryApiClient apiClient,
    required ScopedPrefsStore scopedPrefs,
  })  : _apiClient = apiClient,
        _scopedPrefs = scopedPrefs;

  static const _draftKey = 'oracle_draft';

  final InkqueryApiClient _apiClient;
  final ScopedPrefsStore _scopedPrefs;

  AuthController? _auth;
  String? _boundScope;
  List<ConversationEntry> _messages = const [];
  List<String> _suggestions = const [];
  String _draft = '';
  ChatStage? _stage;
  String? _errorMessage;
  bool _isSending = false;
  int _messageCounter = 0;

  List<ConversationEntry> get messages => List.unmodifiable(_messages);
  List<String> get suggestions => List.unmodifiable(_suggestions);
  String get draft => _draft;
  ChatStage? get stage => _stage;
  String? get errorMessage => _errorMessage;
  bool get isSending => _isSending;

  void bindAuth(AuthController auth) {
    _auth = auth;
    final nextScope = auth.activeScopeKey;
    if (_boundScope == nextScope) {
      return;
    }

    _boundScope = nextScope;
    _messages = const [];
    _suggestions = const [];
    _draft = '';
    _stage = null;
    _errorMessage = null;
    _isSending = false;
    notifyListeners();

    if (nextScope != null) {
      unawaited(_restoreForScope(nextScope));
      unawaited(loadSuggestions());
    }
  }

  Future<void> loadSuggestions() async {
    final auth = _auth;
    if (auth == null || !auth.isAuthenticated) {
      return;
    }

    try {
      final items = await auth.authorizedRequest(
        (session) => _apiClient.getOracleSuggestions(
          baseUrl: session.account.serverUrl,
          accessToken: session.tokens.accessToken,
        ),
      );
      _suggestions = items;
      _errorMessage = null;
      notifyListeners();
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
    }
  }

  Future<void> updateDraft(String value) async {
    _draft = value;
    notifyListeners();

    final scope = _boundScope;
    if (scope != null) {
      await _scopedPrefs.setString(scope, _draftKey, value);
    }
  }

  Future<void> sendMessage(String value) async {
    final message = value.trim();
    final auth = _auth;
    if (message.isEmpty || auth == null || !auth.isAuthenticated || _isSending) {
      return;
    }

    _isSending = true;
    _stage = ChatStage.retrieving;
    _errorMessage = null;
    _messages = [
      ..._messages,
      ConversationEntry(
        id: 'user_${_messageCounter++}',
        isUser: true,
        text: message,
        createdAt: DateTime.now(),
      ),
      ConversationEntry(
        id: 'assistant_${_messageCounter++}',
        isUser: false,
        text: '',
        createdAt: DateTime.now(),
      ),
    ];
    final assistantIndex = _messages.length - 1;
    notifyListeners();

    await updateDraft('');

    try {
      await _streamResponse(auth, message, assistantIndex);
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _replaceAssistantText(
        assistantIndex,
        'I could not finish that request. ${error.message}',
      );
    } catch (_) {
      _errorMessage = 'Something interrupted the response stream.';
      _replaceAssistantText(
        assistantIndex,
        'I lost the response stream before the answer completed.',
      );
    } finally {
      _stage = null;
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> _streamResponse(
    AuthController auth,
    String message,
    int assistantIndex,
  ) async {
    Future<void> execute() async {
      final session = auth.session;
      if (session == null) {
        throw const ApiException(statusCode: 401, message: 'Not signed in.');
      }
      await for (final event in _apiClient.streamChat(
        baseUrl: session.account.serverUrl,
        accessToken: session.tokens.accessToken,
        message: message,
      )) {
        switch (event) {
          case ChatStageEvent():
            _stage = event.stage;
          case ChatAnswerDeltaEvent():
            _appendAssistantDelta(assistantIndex, event.delta);
          case ChatCompleteEvent():
            _messages[assistantIndex] = _messages[assistantIndex].copyWith(
              text: event.payload.answer,
              citations: event.payload.citations,
              actionHints: event.payload.actionHints,
              responseMode: event.payload.responseMode,
            );
        }
        notifyListeners();
      }
    }

    try {
      await execute();
    } on ApiException catch (error) {
      if (error.statusCode != 401) {
        rethrow;
      }
      await auth.refreshActiveSession();
      _messages[assistantIndex] = _messages[assistantIndex].copyWith(text: '');
      notifyListeners();
      await execute();
    }
  }

  void _appendAssistantDelta(int index, String delta) {
    final current = _messages[index];
    _messages[index] = current.copyWith(text: '${current.text}$delta');
  }

  void _replaceAssistantText(int index, String text) {
    final current = _messages[index];
    _messages[index] = current.copyWith(text: text);
  }

  Future<void> _restoreForScope(String scope) async {
    _draft = await _scopedPrefs.getString(scope, _draftKey) ?? '';
    notifyListeners();
  }
}

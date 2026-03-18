import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_models.dart';
import '../models/chat_models.dart';
import '../models/dashboard_models.dart';
import '../models/entity_models.dart';
import '../models/library_models.dart';

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class InkqueryApiClient {
  InkqueryApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  void close() {
    _client.close();
  }

  Future<ServerCapabilities> getCapabilities(String baseUrl) async {
    final json = await _readJson(
      'GET',
      _uri(baseUrl, '/api/v1/auth/capabilities'),
    );
    return ServerCapabilities.fromJson(json);
  }

  Future<void> pingHealth(String baseUrl) async {
    await _readJson('GET', _uri(baseUrl, '/api/v1/health'));
  }

  Future<SessionEnvelope> loginLocal({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    final json = await _readJson(
      'POST',
      _uri(baseUrl, '/api/v1/auth/login'),
      body: {
        'username': username,
        'password': password,
      },
    );
    return SessionEnvelope.fromJson(json);
  }

  Future<SessionEnvelope> refreshSession({
    required String baseUrl,
    required String refreshToken,
  }) async {
    final json = await _readJson(
      'POST',
      _uri(baseUrl, '/api/v1/auth/refresh'),
      body: {'refresh_token': refreshToken},
    );
    return SessionEnvelope.fromJson(json);
  }

  Future<void> logout({
    required String baseUrl,
    required String refreshToken,
  }) async {
    await _readJson(
      'POST',
      _uri(baseUrl, '/api/v1/auth/logout'),
      body: {'refresh_token': refreshToken},
    );
  }

  Future<UserProfile> getMe({
    required String baseUrl,
    required String accessToken,
  }) async {
    final json = await _readJson(
      'GET',
      _uri(baseUrl, '/api/v1/me'),
      accessToken: accessToken,
    );
    return UserProfile.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<List<String>> getOracleSuggestions({
    required String baseUrl,
    required String accessToken,
  }) async {
    final json = await _readJson(
      'GET',
      _uri(baseUrl, '/api/v1/oracle/suggestions'),
      accessToken: accessToken,
    );
    return (json['items'] as List<dynamic>? ?? const []).cast<String>();
  }

  Future<DashboardSummary> getDashboard({
    required String baseUrl,
    required String accessToken,
  }) async {
    final json = await _readJson(
      'GET',
      _uri(baseUrl, '/api/v1/dashboard'),
      accessToken: accessToken,
    );
    return DashboardSummary.fromJson(json);
  }

  Future<List<BookListItem>> getBooks({
    required String baseUrl,
    required String accessToken,
  }) async {
    final json = await _readJson(
      'GET',
      _uri(baseUrl, '/api/v1/library/books'),
      accessToken: accessToken,
    );
    return (json['items'] as List<dynamic>? ?? const [])
        .map((item) => BookListItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BookDetail> getBookDetail({
    required String baseUrl,
    required String accessToken,
    required int bookId,
  }) async {
    final json = await _readJson(
      'GET',
      _uri(baseUrl, '/api/v1/library/books/$bookId'),
      accessToken: accessToken,
    );
    return BookDetail.fromJson(json);
  }

  Future<List<EntitySummary>> getEntities({
    required String baseUrl,
    required String accessToken,
    String query = '',
    String kind = '',
  }) async {
    final json = await _readJson(
      'GET',
      _uri(
        baseUrl,
        '/api/v1/entities',
        queryParameters: {
          if (query.isNotEmpty) 'q': query,
          if (kind.isNotEmpty) 'kind': kind,
        },
      ),
      accessToken: accessToken,
    );
    return (json['items'] as List<dynamic>? ?? const [])
        .map((item) => EntitySummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<EntityDetail> getEntityDetail({
    required String baseUrl,
    required String accessToken,
    required int entityId,
  }) async {
    final json = await _readJson(
      'GET',
      _uri(baseUrl, '/api/v1/entities/$entityId'),
      accessToken: accessToken,
    );
    return EntityDetail.fromJson(json);
  }

  Stream<ChatStreamEvent> streamChat({
    required String baseUrl,
    required String accessToken,
    required String message,
    Duration timeout = const Duration(minutes: 5),
  }) async* {
    final request = http.Request('POST', _uri(baseUrl, '/api/v1/chat/stream'))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      })
      ..body = jsonEncode({'message': message});

    final response = await _client.send(request).timeout(timeout);
    if (response.statusCode >= 400) {
      final body = await response.stream.bytesToString();
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(body, response.statusCode),
      );
    }

    await for (final line
        in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.trim().isEmpty) {
        continue;
      }
      final json = jsonDecode(line) as Map<String, dynamic>;
      switch (json['type'] as String? ?? '') {
        case 'stage':
          yield ChatStageEvent(_parseChatStage(json['stage'] as String? ?? 'retrieving'));
        case 'answer':
          yield ChatAnswerDeltaEvent(json['delta'] as String? ?? '');
        case 'complete':
          yield ChatCompleteEvent(
            ChatResponsePayload.fromJson(json['response'] as Map<String, dynamic>),
          );
      }
    }
  }

  Future<Map<String, dynamic>> _readJson(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    String? accessToken,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final request = http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json';

    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamed = await _client.send(request).timeout(timeout);
    final rawBody = await streamed.stream.bytesToString();
    if (streamed.statusCode >= 400) {
      throw ApiException(
        statusCode: streamed.statusCode,
        message: _extractErrorMessage(rawBody, streamed.statusCode),
      );
    }
    if (rawBody.isEmpty) {
      return const {};
    }
    return jsonDecode(rawBody) as Map<String, dynamic>;
  }

  Uri _uri(
    String baseUrl,
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final base = Uri.parse(baseUrl);
    return base.resolveUri(
      Uri(
        path: path,
        queryParameters: queryParameters?.isEmpty == true ? null : queryParameters,
      ),
    );
  }

  String _extractErrorMessage(String body, int statusCode) {
    if (body.isEmpty) {
      return 'Request failed with status $statusCode.';
    }
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        final detail = json['detail'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {}
    return body;
  }

  ChatStage _parseChatStage(String raw) {
    return switch (raw) {
      'selecting' => ChatStage.selecting,
      'synthesizing' => ChatStage.synthesizing,
      _ => ChatStage.retrieving,
    };
  }
}

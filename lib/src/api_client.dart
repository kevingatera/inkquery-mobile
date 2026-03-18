import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

class InkqueryApiException implements Exception {
  InkqueryApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'InkqueryApiException($statusCode, $message)';
}

class InkqueryApiClient {
  InkqueryApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<AuthCapabilities> getAuthCapabilities(String baseUrl) async {
    final payload = await _requestJson(
      'GET',
      _uri(baseUrl, '/api/v1/auth/capabilities'),
    );
    return AuthCapabilities.fromJson(payload);
  }

  Future<AuthSession> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    final payload = await _requestJson(
      'POST',
      _uri(baseUrl, '/api/v1/auth/login'),
      body: {'username': username, 'password': password},
    );
    return AuthSession.fromJson(payload);
  }

  Future<AuthSession> refresh({
    required String baseUrl,
    required String refreshToken,
  }) async {
    final payload = await _requestJson(
      'POST',
      _uri(baseUrl, '/api/v1/auth/refresh'),
      body: {'refresh_token': refreshToken},
    );
    return AuthSession.fromJson(payload);
  }

  Future<AuthSession> exchangeMobileCode({
    required String baseUrl,
    required String code,
  }) async {
    final payload = await _requestJson(
      'POST',
      _uri(baseUrl, '/api/v1/auth/mobile/exchange'),
      body: {'code': code},
    );
    return AuthSession.fromJson(payload);
  }

  Future<CurrentUser> getMe({
    required String baseUrl,
    required String accessToken,
  }) async {
    final payload = await _requestJson(
      'GET',
      _uri(baseUrl, '/api/v1/me'),
      accessToken: accessToken,
    );
    return CurrentUser.fromJson(payload['user'] as Map<String, dynamic>);
  }

  Future<List<BookItem>> getBooks({
    required String baseUrl,
    required String accessToken,
  }) async {
    final payload = await _requestJson(
      'GET',
      _uri(baseUrl, '/api/v1/library/books'),
      accessToken: accessToken,
    );
    final items = payload['items'] as List<dynamic>? ?? const [];
    return items
        .map((item) => BookItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BookDetail> getBookDetail({
    required String baseUrl,
    required String accessToken,
    required int bookId,
  }) async {
    final payload = await _requestJson(
      'GET',
      _uri(baseUrl, '/api/v1/library/books/$bookId'),
      accessToken: accessToken,
    );
    return BookDetail.fromJson(payload);
  }

  Future<List<EntityItem>> getEntities({
    required String baseUrl,
    required String accessToken,
    String query = '',
  }) async {
    final uri = _uri(
      baseUrl,
      '/api/v1/entities',
      queryParameters: query.isEmpty ? null : {'q': query},
    );
    final payload = await _requestJson(
      'GET',
      uri,
      accessToken: accessToken,
    );
    final items = payload['items'] as List<dynamic>? ?? const [];
    return items
        .map((item) => EntityItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<EntityDetail> getEntityDetail({
    required String baseUrl,
    required String accessToken,
    required int entityId,
  }) async {
    final payload = await _requestJson(
      'GET',
      _uri(baseUrl, '/api/v1/entities/$entityId'),
      accessToken: accessToken,
    );
    return EntityDetail.fromJson(payload);
  }

  Future<ChatResponse> streamChat({
    required String baseUrl,
    required String accessToken,
    required String message,
    ValueChanged<String>? onStage,
    ValueChanged<String>? onAnswerDelta,
  }) async {
    final request = http.Request('POST', _uri(baseUrl, '/api/v1/chat/stream'))
      ..headers.addAll(_headers(accessToken: accessToken))
      ..body = jsonEncode({'message': message});
    final streamed = await _httpClient.send(request);
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final errorBody = await streamed.stream.bytesToString();
      throw _exceptionFromBody(streamed.statusCode, errorBody);
    }

    final completer = Completer<ChatResponse>();
    var buffer = '';
    await for (final chunk in streamed.stream.transform(utf8.decoder)) {
      buffer += chunk;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          continue;
        }
        final event = jsonDecode(trimmed) as Map<String, dynamic>;
        switch (event['type']) {
          case 'stage':
            onStage?.call((event['stage'] as String?) ?? '');
            break;
          case 'answer':
            onAnswerDelta?.call((event['delta'] as String?) ?? '');
            break;
          case 'error':
            throw InkqueryApiException(500, (event['message'] as String?) ?? 'Chat stream failed.');
          case 'complete':
            if (!completer.isCompleted) {
              completer.complete(
                ChatResponse.fromJson(event['response'] as Map<String, dynamic>),
              );
            }
            break;
        }
      }
    }

    if (!completer.isCompleted) {
      throw InkqueryApiException(500, 'Chat stream ended before a final response was received.');
    }
    return completer.future;
  }

  Uri buildOidcStartUri({
    required String baseUrl,
    required String redirectUri,
  }) {
    return _uri(
      baseUrl,
      '/auth/openid',
      queryParameters: {
        'mode': 'mobile',
        'redirect_uri': redirectUri,
      },
    );
  }

  Future<Map<String, dynamic>> _requestJson(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    String? accessToken,
  }) async {
    final response = await _httpClient
        .send(
          http.Request(method, uri)
            ..headers.addAll(_headers(accessToken: accessToken))
            ..body = body == null ? '' : jsonEncode(body),
        )
        .then(http.Response.fromStream);

    final payload = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = payload['detail'] as String?;
      throw InkqueryApiException(
        response.statusCode,
        detail ?? 'Request failed with status ${response.statusCode}.',
      );
    }

    return payload;
  }

  Map<String, String> _headers({String? accessToken}) {
    return {
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
  }

  Uri _uri(String baseUrl, String path, {Map<String, String>? queryParameters}) {
    final normalizedBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$normalizedBase$path').replace(queryParameters: queryParameters);
  }

  InkqueryApiException _exceptionFromBody(int statusCode, String body) {
    try {
      final payload = jsonDecode(body) as Map<String, dynamic>;
      return InkqueryApiException(
        statusCode,
        (payload['detail'] as String?) ?? 'Request failed with status $statusCode.',
      );
    } catch (_) {
      return InkqueryApiException(statusCode, 'Request failed with status $statusCode.');
    }
  }
}

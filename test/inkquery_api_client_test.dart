import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inkquery_mobile/models/auth_models.dart';
import 'package:inkquery_mobile/models/chat_models.dart';
import 'package:inkquery_mobile/services/inkquery_api_client.dart';

void main() {
  group('normalizeServerUrl', () {
    test('adds http and trims trailing slash', () {
      expect(normalizeServerUrl('192.168.1.108:8420/'), 'http://192.168.1.108:8420');
    });
  });

  group('InkqueryApiClient', () {
    test('parses capabilities and login payloads', () async {
      final client = InkqueryApiClient(
        client: MockClient((request) async {
          switch (request.url.path) {
            case '/api/v1/auth/capabilities':
              return http.Response(
                '{"auth_required": true, "local": {"enabled": true}, "oidc": {"enabled": false, "label": null}}',
                200,
              );
            case '/api/v1/auth/login':
              return http.Response(
                '{"access_token":"access-1","refresh_token":"refresh-1","user":{"id":7,"username":"kevin","role":"admin","email":"k@example.com"}}',
                200,
              );
          }
          return http.Response('Not found', 404);
        }),
      );

      final capabilities = await client.getCapabilities('http://example.com');
      expect(capabilities.authRequired, isTrue);
      expect(capabilities.localEnabled, isTrue);
      expect(capabilities.oidcEnabled, isFalse);

      final session = await client.loginLocal(
        baseUrl: 'http://example.com',
        username: 'kevin',
        password: 'password123',
      );
      expect(session.user.username, 'kevin');
      expect(session.tokens.accessToken, 'access-1');
    });

    test('streams ndjson chat responses', () async {
      final client = InkqueryApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/chat/stream');
          expect(request.headers['authorization'], 'Bearer access-1');
          return http.Response(
            '{"type":"stage","stage":"retrieving"}\n'
            '{"type":"answer","delta":"Hello"}\n'
            '{"type":"answer","delta":" world"}\n'
            '{"type":"complete","response":{"answer":"Hello world","response_mode":"synthesized","source_count":1,"citations":[{"title":"Book One","note":"A proof line","locator":"Chapter 2"}],"action_hints":[]}}\n',
            200,
            headers: {'content-type': 'application/x-ndjson'},
          );
        }),
      );

      final events = await client
          .streamChat(
            baseUrl: 'http://example.com',
            accessToken: 'access-1',
            message: 'Who is Nynaeve?',
          )
          .toList();

      expect(events.length, 4);
      expect(events.first, isA<ChatStageEvent>());
      expect(events[1], isA<ChatAnswerDeltaEvent>());
      expect(events.last, isA<ChatCompleteEvent>());

      final complete = events.last as ChatCompleteEvent;
      expect(complete.payload.answer, 'Hello world');
      expect(complete.payload.citations.single.title, 'Book One');
    });
  });
}

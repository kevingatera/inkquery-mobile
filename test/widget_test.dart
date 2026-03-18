import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inkquery_mobile/src/api_client.dart';
import 'package:inkquery_mobile/src/app.dart';
import 'package:inkquery_mobile/src/app_state.dart';
import 'package:inkquery_mobile/src/models.dart';
import 'package:inkquery_mobile/src/token_storage.dart';

class _MemoryTokenStorage implements TokenStorage {
  const _MemoryTokenStorage();

  static final Map<String, String> values = <String, String>{};

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _MemoryTokenStorage.values.clear();
  });

  testWidgets('shows login screen when auth is required and there is no session', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final state = await InkqueryAppState.bootstrap(
      apiClient: _StubApiClient(),
      preferences: preferences,
      tokenStorage: const _MemoryTokenStorage(),
    );

    await tester.pumpWidget(InkqueryMobileApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('Inkquery'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('shows main navigation when auth is not required', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final state = await InkqueryAppState.bootstrap(
      apiClient: _OpenStubApiClient(),
      preferences: preferences,
      tokenStorage: const _MemoryTokenStorage(),
    );

    await tester.pumpWidget(InkqueryMobileApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('Oracle'), findsWidgets);
    expect(find.text('Library'), findsWidgets);
    expect(find.text('Entities'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });
}

class _StubApiClient extends InkqueryApiClient {
  @override
  Future<AuthCapabilities> getAuthCapabilities(String baseUrl) async {
    return const AuthCapabilities(
      authRequired: true,
      localEnabled: true,
      oidcEnabled: false,
      oidcLabel: 'Continue with OpenID',
    );
  }
}

class _OpenStubApiClient extends InkqueryApiClient {
  @override
  Future<AuthCapabilities> getAuthCapabilities(String baseUrl) async {
    return const AuthCapabilities(
      authRequired: false,
      localEnabled: true,
      oidcEnabled: false,
      oidcLabel: 'Continue with OpenID',
    );
  }
}

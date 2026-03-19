import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inkquery_mobile/models/auth_models.dart';
import 'package:inkquery_mobile/providers/auth_controller.dart';
import 'package:inkquery_mobile/providers/chat_controller.dart';
import 'package:inkquery_mobile/providers/entities_controller.dart';
import 'package:inkquery_mobile/providers/library_controller.dart';
import 'package:inkquery_mobile/screens/app_shell.dart';
import 'package:inkquery_mobile/services/inkquery_api_client.dart';
import 'package:inkquery_mobile/services/scoped_prefs_store.dart';
import 'package:inkquery_mobile/src/api_client.dart' as old;
import 'package:inkquery_mobile/src/app.dart';
import 'package:inkquery_mobile/src/app_state.dart';
import 'package:inkquery_mobile/src/models.dart' as old_models;
import 'package:inkquery_mobile/src/token_storage.dart';
import 'package:inkquery_mobile/theme/inkquery_theme.dart';

// ---------------------------------------------------------------------------
// Old-architecture test doubles (used only by the login test)
// ---------------------------------------------------------------------------

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

class _StubApiClient extends old.InkqueryApiClient {
  @override
  Future<old_models.AuthCapabilities> getAuthCapabilities(
    String baseUrl,
  ) async {
    return const old_models.AuthCapabilities(
      authRequired: true,
      localEnabled: true,
      oidcEnabled: false,
      oidcLabel: 'Continue with OpenID',
    );
  }
}

// ---------------------------------------------------------------------------
// Fake AuthController that exposes a pre-set auth state without network.
// ---------------------------------------------------------------------------

class _FakeAuthController extends ChangeNotifier implements AuthController {
  _FakeAuthController({required AuthStatus status, AuthSession? session})
    : _status = status,
      _session = session;

  final AuthStatus _status;
  final AuthSession? _session;

  @override
  AuthStatus get status => _status;

  @override
  AuthSession? get session => _session;

  @override
  bool get isBusy =>
      _status == AuthStatus.starting || _status == AuthStatus.signingIn;

  @override
  bool get isAuthenticated => _status == AuthStatus.ready && _session != null;

  @override
  String? get activeScopeKey => _session?.account.scopeKey;

  @override
  SavedAccount? get activeAccount => _session?.account;

  @override
  List<SavedAccount> get accounts =>
      _session != null ? [_session.account] : const [];

  @override
  String? get errorMessage => null;

  @override
  ServerCapabilities? get capabilities => null;

  @override
  String get suggestedServerUrl => 'http://localhost:8420';

  // Stubs for methods we don't exercise in the widget test.
  @override
  Future<void> initialize() async {}
  @override
  Future<void> inspectServer(String rawServerUrl) async {}
  @override
  Future<bool> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async => false;
  @override
  Future<bool> switchAccount(String scopeKey) async => false;
  @override
  Future<void> removeAccount(String scopeKey) async {}
  @override
  Future<void> logoutCurrent() async {}
  @override
  Future<AuthSession> refreshActiveSession() async =>
      throw UnimplementedError();
  @override
  Future<T> authorizedRequest<T>(
    Future<T> Function(AuthSession session) operation,
  ) async => throw UnimplementedError();
  @override
  void clearError() {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _MemoryTokenStorage.values.clear();
  });

  // Test 1: the old architecture still shows the login screen when auth is
  // required and there is no session.
  testWidgets(
    'shows login screen when auth is required and there is no session',
    (tester) async {
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
    },
  );

  // Test 2: AppShell renders all four navigation destinations when the
  // auth controller reports an authenticated session.
  testWidgets('shows main navigation when authenticated', (tester) async {
    final fakeSession = AuthSession(
      account: SavedAccount(
        serverUrl: 'http://localhost:8420',
        username: 'tester',
        scopeKey: 'localhost_tester',
        lastUsedAt: DateTime.now(),
      ),
      tokens: const SessionTokens(
        accessToken: 'fake-access',
        refreshToken: 'fake-refresh',
      ),
      user: const UserProfile(id: 1, username: 'tester', role: 'admin'),
    );

    final authController = _FakeAuthController(
      status: AuthStatus.ready,
      session: fakeSession,
    );

    final apiClient = InkqueryApiClient();
    const scopedPrefs = ScopedPrefsStore();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: authController),
          Provider<InkqueryApiClient>.value(value: apiClient),
          ChangeNotifierProvider<ChatController>(
            create: (_) =>
                ChatController(apiClient: apiClient, scopedPrefs: scopedPrefs),
          ),
          ChangeNotifierProvider<LibraryController>(
            create: (_) => LibraryController(
              apiClient: apiClient,
              scopedPrefs: scopedPrefs,
            ),
          ),
          ChangeNotifierProvider<EntitiesController>(
            create: (_) => EntitiesController(
              apiClient: apiClient,
              scopedPrefs: scopedPrefs,
            ),
          ),
        ],
        child: MaterialApp(theme: InkqueryTheme.theme, home: const AppShell()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Oracle'), findsWidgets);
    expect(find.text('Library'), findsWidgets);
    expect(find.text('Entities'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });
}

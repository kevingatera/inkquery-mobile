import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_controller.dart';
import '../providers/chat_controller.dart';
import '../providers/entities_controller.dart';
import '../providers/library_controller.dart';
import '../screens/app_shell.dart';
import '../screens/login_screen.dart';
import '../services/account_store.dart';
import '../services/inkquery_api_client.dart' as svc;
import '../services/scoped_prefs_store.dart';
import '../services/secure_token_store.dart';
import '../theme/inkquery_theme.dart';
import 'app_state.dart';

class InkqueryMobileApp extends StatefulWidget {
  const InkqueryMobileApp({super.key, required this.state});

  final InkqueryAppState state;

  @override
  State<InkqueryMobileApp> createState() => _InkqueryMobileAppState();
}

class _InkqueryMobileAppState extends State<InkqueryMobileApp> {
  late final svc.InkqueryApiClient _apiClient;
  late final AccountStore _accountStore;
  late final SecureTokenStore _tokenStore;
  late final ScopedPrefsStore _scopedPrefs;
  late final AuthController _authController;
  late final ChatController _chatController;
  late final LibraryController _libraryController;
  late final EntitiesController _entitiesController;

  @override
  void initState() {
    super.initState();
    _apiClient = svc.InkqueryApiClient();
    _accountStore = AccountStore();
    _tokenStore = SecureTokenStore();
    _scopedPrefs = const ScopedPrefsStore();

    _authController = AuthController(
      apiClient: _apiClient,
      accountStore: _accountStore,
      tokenStore: _tokenStore,
    );
    _chatController = ChatController(
      apiClient: _apiClient,
      scopedPrefs: _scopedPrefs,
    );
    _libraryController = LibraryController(
      apiClient: _apiClient,
      scopedPrefs: _scopedPrefs,
    );
    _entitiesController = EntitiesController(
      apiClient: _apiClient,
      scopedPrefs: _scopedPrefs,
    );

    _authController.addListener(_onAuthChanged);
    _authController.initialize();
  }

  void _onAuthChanged() {
    _chatController.bindAuth(_authController);
    _libraryController.bindAuth(_authController);
    _entitiesController.bindAuth(_authController);
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChanged);
    _authController.dispose();
    _chatController.dispose();
    _libraryController.dispose();
    _entitiesController.dispose();
    _apiClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<InkqueryAppState>.value(value: widget.state),
        ChangeNotifierProvider<AuthController>.value(value: _authController),
        ChangeNotifierProvider<ChatController>.value(value: _chatController),
        ChangeNotifierProvider<LibraryController>.value(
          value: _libraryController,
        ),
        ChangeNotifierProvider<EntitiesController>.value(
          value: _entitiesController,
        ),
        Provider<svc.InkqueryApiClient>.value(value: _apiClient),
      ],
      child: MaterialApp(
        title: 'Inkquery',
        debugShowCheckedModeBanner: false,
        theme: InkqueryTheme.theme,
        home: Consumer<AuthController>(
          builder: (context, auth, _) {
            if (auth.isBusy) {
              return Scaffold(
                backgroundColor: InkqueryTheme.paper,
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 16,
                    children: [
                      Text(
                        'Inkquery',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!auth.isAuthenticated) {
              return const LoginScreen();
            }
            return const AppShell();
          },
        ),
      ),
    );
  }
}

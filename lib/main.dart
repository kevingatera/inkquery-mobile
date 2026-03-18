import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/api_client.dart';
import 'src/app.dart';
import 'src/app_state.dart';
import 'src/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final apiClient = InkqueryApiClient();
  final appState = await InkqueryAppState.bootstrap(
    apiClient: apiClient,
    preferences: preferences,
    tokenStorage: const SecureTokenStorage(),
  );

  runApp(InkqueryMobileApp(state: appState));
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth_models.dart';
import '../providers/auth_controller.dart';
import '../widgets/ink_panel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _serverController;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final suggested = context.read<AuthController>().suggestedServerUrl;
    if (_serverController.text.isEmpty) {
      _serverController.text = suggested;
    }
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8EDDE),
              Color(0xFFE0EEEA),
              Color(0xFFF6DFC9),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<AuthController>(
            builder: (context, auth, _) {
              final capabilities = auth.capabilities;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 18,
                  children: [
                    Text(
                      'Inkquery on your phone',
                      style: theme.textTheme.headlineLarge,
                    ),
                    Text(
                      'Point the app at your Inkquery API, sign in with a local household account, and carry the oracle, library, and entity graph with you.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    InkPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 14,
                        children: [
                          Text('Connect to a server', style: theme.textTheme.titleLarge),
                          TextField(
                            controller: _serverController,
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Inkquery API URL',
                              hintText: 'http://192.168.1.108:8420',
                            ),
                          ),
                          TextField(
                            controller: _usernameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                            ),
                          ),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            onSubmitted: (_) => _submit(context),
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                          ),
                          if (auth.errorMessage != null)
                            Text(
                              auth.errorMessage!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              OutlinedButton.icon(
                                onPressed: auth.isBusy
                                    ? null
                                    : () => auth.inspectServer(_serverController.text),
                                icon: const Icon(Icons.radar_outlined),
                                label: const Text('Check server'),
                              ),
                              FilledButton.icon(
                                onPressed: auth.isBusy ? null : () => _submit(context),
                                icon: auth.isBusy
                                    ? const SizedBox.square(
                                        dimension: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.login_rounded),
                                label: Text(auth.isBusy ? 'Signing in...' : 'Sign in'),
                              ),
                            ],
                          ),
                          if (capabilities != null)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  label: Text(
                                    capabilities.authRequired
                                        ? 'Auth required'
                                        : 'Auth optional',
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    capabilities.localEnabled
                                        ? 'Local accounts enabled'
                                        : 'Local accounts disabled',
                                  ),
                                ),
                                if (capabilities.oidcEnabled)
                                  Chip(
                                    label: Text(
                                      capabilities.oidcLabel?.isNotEmpty == true
                                          ? capabilities.oidcLabel!
                                          : 'OIDC available',
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (auth.accounts.isNotEmpty)
                      InkPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 12,
                          children: [
                            Text('Saved accounts', style: theme.textTheme.titleLarge),
                            ...auth.accounts.map(
                              (account) => _SavedAccountRow(
                                account: account,
                                onSwitch: () => auth.switchAccount(account.scopeKey),
                                onDelete: () => auth.removeAccount(account.scopeKey),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final auth = context.read<AuthController>();
    await auth.login(
      serverUrl: _serverController.text,
      username: _usernameController.text,
      password: _passwordController.text,
    );
  }
}

class _SavedAccountRow extends StatelessWidget {
  const _SavedAccountRow({
    required this.account,
    required this.onSwitch,
    required this.onDelete,
  });

  final SavedAccount account;
  final VoidCallback onSwitch;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Ink(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text(account.username, style: theme.textTheme.titleMedium),
        subtitle: Text(account.serverUrl),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove account',
            ),
            FilledButton.tonal(
              onPressed: onSwitch,
              child: const Text('Use'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth_models.dart';
import '../providers/auth_controller.dart';
import '../theme/inkquery_theme.dart';
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
        decoration: const BoxDecoration(color: InkqueryTheme.paper),
        child: SafeArea(
          child: Consumer<AuthController>(
            builder: (context, auth, _) {
              final capabilities = auth.capabilities;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 14,
                      children: [
                        Text('Inkquery', style: theme.textTheme.headlineLarge),
                        Text(
                          'Sign in to your household server.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        InkPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 12,
                            children: [
                              TextField(
                                controller: _serverController,
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Server',
                                  hintText: 'http://192.168.1.108:8420',
                                ),
                              ),
                              TextField(
                                controller: _usernameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(labelText: 'Username'),
                              ),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                onSubmitted: (_) => _submit(context),
                                decoration: const InputDecoration(labelText: 'Password'),
                              ),
                              if (auth.errorMessage != null)
                                Text(
                                  auth.errorMessage!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: auth.isBusy
                                          ? null
                                          : () => auth.inspectServer(_serverController.text),
                                      child: const Text('Check server'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: auth.isBusy ? null : () => _submit(context),
                                      child: Text(auth.isBusy ? 'Signing in...' : 'Sign in'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (capabilities != null)
                          InkPanel(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 8,
                              children: [
                                Text('Server capabilities', style: theme.textTheme.titleMedium),
                                Text(
                                  [
                                    capabilities.authRequired ? 'Auth required' : 'Auth optional',
                                    capabilities.localEnabled ? 'Local accounts' : 'Local disabled',
                                    if (capabilities.oidcEnabled)
                                      capabilities.oidcLabel?.isNotEmpty == true
                                          ? capabilities.oidcLabel!
                                          : 'OIDC',
                                  ].join('  ·  '),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        if (auth.accounts.isNotEmpty)
                          InkPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 8,
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
                  ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(account.username, style: theme.textTheme.titleMedium),
                Text(account.hostLabel, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
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
    );
  }
}

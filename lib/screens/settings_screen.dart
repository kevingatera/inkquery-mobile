import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth_models.dart';
import '../models/dashboard_models.dart';
import '../providers/auth_controller.dart';
import '../services/inkquery_api_client.dart';
import '../widgets/ink_panel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<DashboardSummary>? _dashboardFuture;
  String? _boundScope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthController>();
    final scope = auth.activeScopeKey;
    if (scope == _boundScope) {
      return;
    }
    _boundScope = scope;
    if (scope == null) {
      _dashboardFuture = null;
      return;
    }
    final api = context.read<InkqueryApiClient>();
    _dashboardFuture = auth.authorizedRequest(
      (session) => api.getDashboard(
        baseUrl: session.account.serverUrl,
        accessToken: session.tokens.accessToken,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final session = auth.session;
    final theme = Theme.of(context);

    if (session == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      children: [
        InkPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text('Current account', style: theme.textTheme.titleLarge),
              Text(session.account.title, style: theme.textTheme.titleMedium),
              Text(session.account.serverUrl, style: theme.textTheme.bodySmall),
              Text(
                [
                  session.user.role,
                  if (session.user.email?.isNotEmpty == true) session.user.email!,
                ].join('  ·  '),
                style: theme.textTheme.bodySmall,
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => auth.refreshActiveSession(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh session'),
                  ),
                  FilledButton.icon(
                    onPressed: auth.logoutCurrent,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text('Saved accounts', style: theme.textTheme.titleLarge),
              ...auth.accounts.map(
                (account) => _SavedAccountTile(
                  account: account,
                  activeScopeKey: auth.activeScopeKey,
                  onSwitch: () => auth.switchAccount(account.scopeKey),
                  onDelete: () => auth.removeAccount(account.scopeKey),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showAddAccountSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Add another account'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkPanel(
          child: FutureBuilder<DashboardSummary>(
            future: _dashboardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'Dashboard unavailable: ${snapshot.error}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                );
              }
              final dashboard = snapshot.data;
              if (dashboard == null) {
                return const Text('No dashboard data available.');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Text('Server snapshot', style: theme.textTheme.titleLarge),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Text('${dashboard.counts.books} books', style: theme.textTheme.bodySmall),
                      Text('${dashboard.counts.passages} passages', style: theme.textTheme.bodySmall),
                      Text('${dashboard.counts.entities} entities', style: theme.textTheme.bodySmall),
                    ],
                  ),
                  ...dashboard.connectors.map(
                    (connector) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(connector.name),
                      subtitle: Text(connector.detail),
                      trailing: Text(connector.status, style: theme.textTheme.bodySmall),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAddAccountSheet(BuildContext context) async {
    final auth = context.read<AuthController>();
    final api = context.read<InkqueryApiClient>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddAccountSheet(),
    );
    if (!mounted) {
      return;
    }
    if (auth.activeScopeKey != _boundScope) {
      setState(() {
        _boundScope = auth.activeScopeKey;
        _dashboardFuture = auth.activeScopeKey == null
            ? null
            : auth.authorizedRequest(
                (session) => api.getDashboard(
                  baseUrl: session.account.serverUrl,
                  accessToken: session.tokens.accessToken,
                ),
              );
      });
    }
  }
}

class _SavedAccountTile extends StatelessWidget {
  const _SavedAccountTile({
    required this.account,
    required this.activeScopeKey,
    required this.onSwitch,
    required this.onDelete,
  });

  final SavedAccount account;
  final String? activeScopeKey;
  final VoidCallback onSwitch;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(account.username),
      subtitle: Text(account.hostLabel),
      leading: Icon(
        account.scopeKey == activeScopeKey
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
          if (account.scopeKey != activeScopeKey)
            FilledButton.tonal(onPressed: onSwitch, child: const Text('Switch')),
        ],
      ),
      dense: true,
    );
  }
}

class _AddAccountSheet extends StatefulWidget {
  const _AddAccountSheet();

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  late final TextEditingController _serverController;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _localError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_serverController.text.isEmpty) {
      _serverController.text = context.read<AuthController>().suggestedServerUrl;
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          const SizedBox(height: 4),
          Text('Add another account', style: Theme.of(context).textTheme.titleLarge),
          Text(
            'Use this for another household member or another Inkquery server.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          TextField(
            controller: _serverController,
            decoration: const InputDecoration(labelText: 'Server URL'),
          ),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            onSubmitted: (_) => _submit(context),
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          if (_localError != null)
            Text(
              _localError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : () => _submit(context),
            icon: _isSubmitting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: Text(_isSubmitting ? 'Signing in...' : 'Add account'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final auth = context.read<AuthController>();
    final navigator = Navigator.of(context);
    setState(() {
      _localError = null;
      _isSubmitting = true;
    });

    final success = await auth.login(
      serverUrl: _serverController.text,
      username: _usernameController.text,
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      _localError = success ? null : auth.errorMessage;
    });

    if (success) {
      navigator.pop();
    }
  }
}

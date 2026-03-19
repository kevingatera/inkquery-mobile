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
    final scheme = theme.colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: InkqueryTheme.paper),
        child: SafeArea(
          child: Consumer<AuthController>(
            builder: (context, auth, _) {
              final capabilities = auth.capabilities;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Branded header ---
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            size: 28,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Inkquery', style: theme.textTheme.headlineLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to your household server.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // --- Login form ---
                        InkPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _serverController,
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Server',
                                  hintText: 'http://192.168.1.108:8420',
                                  prefixIcon: Icon(Icons.dns_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _usernameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                onSubmitted: (_) => _submit(context),
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                              ),

                              if (auth.errorMessage != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 16,
                                        color: scheme.error,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          auth.errorMessage!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: scheme.onErrorContainer,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: auth.isBusy
                                          ? null
                                          : () => auth.inspectServer(
                                              _serverController.text,
                                            ),
                                      icon: const Icon(
                                        Icons.wifi_find,
                                        size: 18,
                                      ),
                                      label: const Text('Check server'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: auth.isBusy
                                          ? null
                                          : () => _submit(context),
                                      icon: auth.isBusy
                                          ? const SizedBox.square(
                                              dimension: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.login, size: 18),
                                      label: Text(
                                        auth.isBusy
                                            ? 'Signing in...'
                                            : 'Sign in',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // --- Server capabilities ---
                        if (capabilities != null) ...[
                          const SizedBox(height: 14),
                          InkPanel(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Server capabilities',
                                        style: theme.textTheme.labelLarge,
                                      ),
                                      const SizedBox(height: 2),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          _CapBadge(
                                            label: capabilities.authRequired
                                                ? 'Auth required'
                                                : 'Auth optional',
                                            active: capabilities.authRequired,
                                          ),
                                          _CapBadge(
                                            label: 'Local accounts',
                                            active: capabilities.localEnabled,
                                          ),
                                          if (capabilities.oidcEnabled)
                                            _CapBadge(
                                              label:
                                                  capabilities
                                                          .oidcLabel
                                                          ?.isNotEmpty ==
                                                      true
                                                  ? capabilities.oidcLabel!
                                                  : 'OIDC',
                                              active: true,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // --- Saved accounts ---
                        if (auth.accounts.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          InkPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saved accounts',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                ...auth.accounts.map(
                                  (account) => _SavedAccountRow(
                                    account: account,
                                    onSwitch: () =>
                                        auth.switchAccount(account.scopeKey),
                                    onDelete: () =>
                                        auth.removeAccount(account.scopeKey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

// ---------------------------------------------------------------------------
// Capability badge
// ---------------------------------------------------------------------------

class _CapBadge extends StatelessWidget {
  const _CapBadge({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: active ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: active ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Saved account row
// ---------------------------------------------------------------------------

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
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              account.username.isNotEmpty
                  ? account.username[0].toUpperCase()
                  : '?',
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.username, style: theme.textTheme.titleMedium),
                Text(account.hostLabel, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Remove account',
          ),
          FilledButton.tonal(onPressed: onSwitch, child: const Text('Use')),
        ],
      ),
    );
  }
}

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

    if (session == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // --- Active account card ---
        _ActiveAccountCard(session: session, auth: auth),
        const SizedBox(height: 16),

        // --- Saved accounts ---
        _SavedAccountsPanel(
          accounts: auth.accounts,
          activeScopeKey: auth.activeScopeKey,
          onSwitch: (scopeKey) => auth.switchAccount(scopeKey),
          onDelete: (scopeKey) => auth.removeAccount(scopeKey),
          onAdd: () => _showAddAccountSheet(context),
        ),
        const SizedBox(height: 16),

        // --- Dashboard snapshot ---
        _DashboardPanel(future: _dashboardFuture),
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

// ---------------------------------------------------------------------------
// Active account card — avatar, name, role badge, server, actions
// ---------------------------------------------------------------------------

class _ActiveAccountCard extends StatelessWidget {
  const _ActiveAccountCard({required this.session, required this.auth});

  final AuthSession session;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final initials = session.user.username.isNotEmpty
        ? session.user.username.substring(0, 1).toUpperCase()
        : '?';

    return InkPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle_rounded,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 6),
              Text('Current account', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: scheme.primary,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username + role badge
                    Row(
                      children: [
                        Text(
                          session.user.username,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: session.user.isAdmin
                                ? scheme.secondaryContainer
                                : scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            session.user.role,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: session.user.isAdmin
                                  ? scheme.secondary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Server URL
                    Row(
                      children: [
                        Icon(
                          Icons.dns_outlined,
                          size: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            session.account.serverUrl,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Email
                    if (session.user.email?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.mail_outline_rounded,
                            size: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              session.user.email!,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => auth.refreshActiveSession(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: auth.logoutCurrent,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign out'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Saved accounts panel
// ---------------------------------------------------------------------------

class _SavedAccountsPanel extends StatelessWidget {
  const _SavedAccountsPanel({
    required this.accounts,
    required this.activeScopeKey,
    required this.onSwitch,
    required this.onDelete,
    required this.onAdd,
  });

  final List<SavedAccount> accounts;
  final String? activeScopeKey;
  final void Function(String) onSwitch;
  final void Function(String) onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 6),
              Text('Saved accounts', style: theme.textTheme.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${accounts.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...accounts.map((account) {
            final isActive = account.scopeKey == activeScopeKey;
            final initial = account.username.isNotEmpty
                ? account.username.substring(0, 1).toUpperCase()
                : '?';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? scheme.primaryContainer.withValues(alpha: 0.4)
                      : scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: isActive
                      ? Border.all(color: scheme.primary.withValues(alpha: 0.3))
                      : null,
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isActive
                            ? scheme.primaryContainer
                            : scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                          color: isActive
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                account.username,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                              if (isActive) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Active',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            account.hostLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    if (!isActive)
                      SizedBox(
                        height: 30,
                        child: FilledButton.tonal(
                          onPressed: () => onSwitch(account.scopeKey),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Switch'),
                        ),
                      ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: IconButton(
                        onPressed: () => onDelete(account.scopeKey),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.surfaceContainerHigh
                              .withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add another account'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard panel — stat grid + connector chips
// ---------------------------------------------------------------------------

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({required this.future});

  final Future<DashboardSummary>? future;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkPanel(
      padding: const EdgeInsets.all(18),
      child: FutureBuilder<DashboardSummary>(
        future: future,
        builder: (context, snapshot) {
          // Header always visible
          final header = Row(
            children: [
              Icon(Icons.dashboard_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text('Server snapshot', style: theme.textTheme.titleMedium),
            ],
          );

          if (snapshot.connectionState != ConnectionState.done) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          }

          if (snapshot.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 12),
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
                        Icons.cloud_off_rounded,
                        size: 16,
                        color: scheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dashboard unavailable',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          final dashboard = snapshot.data;
          if (dashboard == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 12),
                Text(
                  'No dashboard data available.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 14),

              // --- Stat grid (3 cards) ---
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.menu_book_rounded,
                      label: 'Books',
                      value: '${dashboard.counts.books}',
                      color: scheme.primary,
                      bgColor: scheme.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.format_quote_rounded,
                      label: 'Passages',
                      value: '${dashboard.counts.passages}',
                      color: scheme.secondary,
                      bgColor: scheme.secondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.hub_rounded,
                      label: 'Entities',
                      value: '${dashboard.counts.entities}',
                      color: scheme.tertiary,
                      bgColor: scheme.tertiaryContainer,
                    ),
                  ),
                ],
              ),

              // --- Connectors ---
              if (dashboard.connectors.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.extension_outlined,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Connectors',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...dashboard.connectors.map(
                  (connector) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ConnectorTile(connector: connector),
                  ),
                ),
              ],

              // --- Workflow ---
              if (dashboard.workflow.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.route_outlined,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Workflow',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: dashboard.workflow.asMap().entries.map((entry) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entry.key > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Text(
                            entry.value,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat card for the dashboard grid
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 22,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Connector tile — name, detail, status chip
// ---------------------------------------------------------------------------

class _ConnectorTile extends StatelessWidget {
  const _ConnectorTile({required this.connector});

  final DashboardConnector connector;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (statusColor, statusBg, statusIcon) = _statusVisuals(
      connector.status,
      scheme,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Connector icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.extension_rounded,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connector.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
                ),
                if (connector.detail.isNotEmpty)
                  Text(
                    connector.detail,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 11, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  connector.status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, IconData) _statusVisuals(String status, ColorScheme scheme) {
    return switch (status.toLowerCase()) {
      'ok' || 'connected' || 'active' || 'ready' => (
        scheme.primary,
        scheme.primaryContainer,
        Icons.check_circle_rounded,
      ),
      'error' || 'failed' || 'disconnected' => (
        scheme.error,
        scheme.errorContainer,
        Icons.cancel_rounded,
      ),
      'pending' || 'syncing' || 'processing' => (
        scheme.secondary,
        scheme.secondaryContainer,
        Icons.sync_rounded,
      ),
      _ => (
        scheme.onSurfaceVariant,
        scheme.surfaceContainerLow,
        Icons.circle_outlined,
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// Add account bottom sheet (kept functionally identical, styled to match)
// ---------------------------------------------------------------------------

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
      _serverController.text = context
          .read<AuthController>()
          .suggestedServerUrl;
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person_add_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text('Add another account', style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Use this for another household member or another Inkquery server.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _serverController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.dns_outlined, size: 20),
              labelText: 'Server URL',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              labelText: 'Username',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            onSubmitted: (_) => _submit(context),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
              labelText: 'Password',
            ),
          ),
          if (_localError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: scheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _localError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : () => _submit(context),
              icon: _isSubmitting
                  ? SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(_isSubmitting ? 'Signing in...' : 'Add account'),
            ),
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

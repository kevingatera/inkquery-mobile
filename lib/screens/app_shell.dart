import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_controller.dart';
import '../theme/inkquery_theme.dart';
import 'entities_screen.dart';
import 'library_screen.dart';
import 'oracle_screen.dart';
import 'settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _pages = [
    OracleScreen(),
    LibraryScreen(),
    EntitiesScreen(),
    SettingsScreen(),
  ];

  static const _titles = ['Oracle', 'Library', 'Entities', 'Settings'];

  static const _subtitles = [
    'Ask grounded questions and inspect citations.',
    'Browse the ingested shelf and open sample passages.',
    'Search extracted people, places, factions, and concepts.',
    'Switch accounts and check the connected server.',
  ];

  static const _icons = [
    Icons.auto_awesome,
    Icons.menu_book,
    Icons.hub,
    Icons.tune,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final session = context.select<AuthController, dynamic>(
      (auth) => auth.session,
    );
    final user = session?.user.username as String?;
    final role = session?.user.role as String?;
    final host = session?.account.hostLabel as String?;

    return Scaffold(
      body: DecoratedBox(
        decoration: InkqueryTheme.backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              // --- Header card ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: [
                        // Page icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _icons[_index],
                            size: 20,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title / subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _titles[_index],
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _subtitles[_index],
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Avatar
                        if (user != null)
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              user.isNotEmpty ? user[0].toUpperCase() : 'I',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Connection badge
              if (host != null || user != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: scheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          [host, user, role].whereType<String>().join('  ·  '),
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 4),
              Divider(height: 1, color: scheme.outlineVariant),

              // --- Page content ---
              Expanded(
                child: IndexedStack(index: _index, children: _pages),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Oracle',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub),
            label: 'Entities',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

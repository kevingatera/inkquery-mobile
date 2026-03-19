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

  static const _titles = [
    'Oracle',
    'Library',
    'Entities',
    'Settings',
  ];
  static const _subtitles = [
    'Ask grounded questions and inspect citations.',
    'Browse the ingested shelf and open sample passages.',
    'Search extracted people, places, factions, and concepts.',
    'Switch accounts and check the connected server.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.select<AuthController, dynamic>((auth) => auth.session);
    final user = session?.user.username as String?;
    final role = session?.user.role as String?;
    final host = session?.account.hostLabel as String?;

    return Scaffold(
      body: DecoratedBox(
        decoration: InkqueryTheme.backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 2,
                            children: [
                              Text(
                                _titles[_index],
                                style: theme.textTheme.headlineMedium,
                              ),
                              Text(
                                _subtitles[_index],
                                style: theme.textTheme.bodySmall,
                              ),
                              if (host != null || user != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    [
                                      host,
                                      user,
                                      role,
                                    ].whereType<String>().join('  ·  '),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (user != null)
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainer,
                              border: Border.all(color: theme.colorScheme.outlineVariant),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              user.isNotEmpty ? user[0].toUpperCase() : 'I',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              const Expanded(
                child: IndexedStack(children: _pages),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 62,
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
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

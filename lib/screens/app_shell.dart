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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.select<AuthController, String?>(
      (auth) => auth.session?.user.username,
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: InkqueryTheme.backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titles[_index],
                            style: theme.textTheme.headlineMedium,
                          ),
                          if (user != null)
                            Text(
                              'Signed in as $user',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      foregroundColor: theme.colorScheme.onSecondaryContainer,
                      child: Text(
                        (user?.isNotEmpty == true ? user![0] : 'I').toUpperCase(),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const Expanded(
                child: IndexedStack(children: _pages),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
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

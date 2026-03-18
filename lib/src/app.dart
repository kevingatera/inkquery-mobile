import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'models.dart';

class InkqueryMobileApp extends StatelessWidget {
  const InkqueryMobileApp({super.key, required this.state});

  final InkqueryAppState state;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<InkqueryAppState>.value(
      value: state,
      child: MaterialApp(
        title: 'Inkquery Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF176B5D),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF6F3EB),
          useMaterial3: true,
        ),
        home: const _RootView(),
      ),
    );
  }
}

class _RootView extends StatelessWidget {
  const _RootView();

  @override
  Widget build(BuildContext context) {
    return Consumer<InkqueryAppState>(
      builder: (context, state, _) {
        if (state.initializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.requiresLogin) {
          return const LoginScreen();
        }
        return const HomeScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final serverUrl = context.read<InkqueryAppState>().serverUrl;
    if (_serverController.text != serverUrl) {
      _serverController.text = serverUrl;
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
    final state = context.watch<InkqueryAppState>();
    final appState = context.read<InkqueryAppState>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text('Inkquery', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 12),
              Text(
                'Android-first mobile access for your household oracle.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _serverController,
                decoration: const InputDecoration(
                  labelText: 'API server',
                  hintText: 'http://192.168.1.108:8420',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.busy
                      ? null
                      : () async {
                          final targetUrl = _serverController.text.trim();
                          if (targetUrl != state.serverUrl) {
                            await appState.updateServerUrl(targetUrl);
                          }
                          if (!mounted) {
                            return;
                          }
                          await appState.login(
                                _usernameController.text,
                                _passwordController.text,
                              );
                        },
                  child: Text(state.busy ? 'Signing in...' : 'Sign in'),
                ),
              ),
              if (state.capabilities?.oidcEnabled == true) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: state.busy
                        ? null
                        : () => context.read<InkqueryAppState>().loginWithOidc(),
                    child: Text(state.capabilities?.oidcLabel ?? 'Continue with OpenID'),
                  ),
                ),
              ],
              if (state.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InkqueryAppState>();
    final pages = [
      const OracleTab(),
      const LibraryTab(),
      const EntitiesTab(),
      const SettingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inkquery Mobile'),
        actions: [
          IconButton(
            onPressed: state.busy ? null : () => context.read<InkqueryAppState>().refreshData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.errorMessage != null)
            MaterialBanner(
              content: Text(state.errorMessage!),
              actions: [
                TextButton(
                  onPressed: () => context.read<InkqueryAppState>().refreshData(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.forum_outlined), label: 'Oracle'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.hub_outlined), label: 'Entities'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

class OracleTab extends StatefulWidget {
  const OracleTab({super.key});

  @override
  State<OracleTab> createState() => _OracleTabState();
}

class _OracleTabState extends State<OracleTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InkqueryAppState>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ask the oracle', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Ask about a character, faction, or side-story thread.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: state.chatBusy
                        ? null
                        : () => context.read<InkqueryAppState>().askOracle(_controller.text),
                    child: Text(state.chatBusy ? 'Streaming...' : 'Send question'),
                  ),
                  if (state.chatBusy || state.chatDraftAnswer.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Stage: ${state.chatStage.isEmpty ? 'working' : state.chatStage}'),
                    const SizedBox(height: 8),
                    Text(state.chatDraftAnswer),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: state.chatHistory.length,
              itemBuilder: (context, index) {
                final exchange = state.chatHistory[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exchange.question, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(exchange.answer),
                        if (exchange.citations.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text('Citations', style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 8),
                          ...exchange.citations.map(
                            (citation) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('${citation.title} • ${citation.locator}\n${citation.note}'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InkqueryAppState>();
    if (state.books.isEmpty) {
      return const Center(child: Text('No indexed books available yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.books.length,
      itemBuilder: (context, index) {
        final book = state.books[index];
        return Card(
          child: ListTile(
            title: Text(book.title),
            subtitle: Text([
              book.authorName,
              book.seriesName,
              '${book.passageCount} passages',
            ].whereType<String>().join(' • ')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBookDetailSheet(context, book),
          ),
        );
      },
    );
  }

  Future<void> _showBookDetailSheet(BuildContext context, BookItem book) async {
    final state = context.read<InkqueryAppState>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FutureBuilder<BookDetail>(
          future: state.loadBookDetail(book.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final detail = snapshot.data!;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detail.title, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text([
                        detail.authorName,
                        detail.seriesName,
                        detail.fileFormat,
                      ].whereType<String>().join(' • ')),
                      const SizedBox(height: 12),
                      Text('Passages: ${detail.passageCount}'),
                      if (detail.sourcePath != null) ...[
                        const SizedBox(height: 8),
                        Text(detail.sourcePath!),
                      ],
                      const SizedBox(height: 16),
                      Text('Sample passages', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...detail.samplePassages.map(
                        (passage) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text('${passage.chapterLabel ?? 'Passage'}\n${passage.excerpt}'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class EntitiesTab extends StatefulWidget {
  const EntitiesTab({super.key});

  @override
  State<EntitiesTab> createState() => _EntitiesTabState();
}

class _EntitiesTabState extends State<EntitiesTab> {
  final _filterController = TextEditingController();

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InkqueryAppState>();
    final query = _filterController.text.trim().toLowerCase();
    final items = state.entities.where((item) {
      if (query.isEmpty) {
        return true;
      }
      return item.name.toLowerCase().contains(query) ||
          item.kind.toLowerCase().contains(query) ||
          item.summary.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _filterController,
            decoration: const InputDecoration(
              labelText: 'Filter entities',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No matching entities found.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final entity = items[index];
                    return Card(
                      child: ListTile(
                        title: Text(entity.name),
                        subtitle: Text('${entity.kind} • ${entity.summary}'),
                        onTap: () => _showEntityDetailSheet(context, entity),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showEntityDetailSheet(BuildContext context, EntityItem entity) async {
    final state = context.read<InkqueryAppState>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FutureBuilder<EntityDetail>(
          future: state.loadEntityDetail(entity.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final detail = snapshot.data!;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detail.name, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(detail.kind),
                      const SizedBox(height: 12),
                      Text(detail.summary),
                      const SizedBox(height: 16),
                      Text('Mentions', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...detail.mentions.map(
                        (mention) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text('${mention.title} • ${mention.chapterLabel ?? 'Passage'}\n${mention.excerpt}'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late final TextEditingController _serverController;

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final serverUrl = context.read<InkqueryAppState>().serverUrl;
    if (_serverController.text != serverUrl) {
      _serverController.text = serverUrl;
    }
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InkqueryAppState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connection', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(
                  controller: _serverController,
                  decoration: const InputDecoration(labelText: 'API server'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.read<InkqueryAppState>().updateServerUrl(_serverController.text),
                  child: const Text('Save server'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(state.currentUser == null
                    ? 'Not signed in'
                    : '${state.currentUser!.username} • ${state.currentUser!.role}'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.read<InkqueryAppState>().logout(),
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

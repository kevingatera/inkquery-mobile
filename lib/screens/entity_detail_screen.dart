import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/entity_models.dart';
import '../providers/auth_controller.dart';
import '../services/inkquery_api_client.dart';
import '../widgets/ink_panel.dart';

class EntityDetailScreen extends StatefulWidget {
  const EntityDetailScreen({required this.entityId, super.key});

  final int entityId;

  @override
  State<EntityDetailScreen> createState() => _EntityDetailScreenState();
}

class _EntityDetailScreenState extends State<EntityDetailScreen> {
  late Future<EntityDetail> _future;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    final api = context.read<InkqueryApiClient>();
    _future = auth.authorizedRequest(
      (session) => api.getEntityDetail(
        baseUrl: session.account.serverUrl,
        accessToken: session.tokens.accessToken,
        entityId: widget.entityId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Entity detail')),
      body: FutureBuilder<EntityDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final entity = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              InkPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Text(entity.name, style: theme.textTheme.headlineMedium),
                    Chip(label: Text(entity.kind)),
                    Text(entity.summary, style: theme.textTheme.bodyMedium),
                    if (entity.aliasesJson.isNotEmpty)
                      Text(entity.aliasesJson, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ...entity.mentions.map(
                (mention) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        Text(mention.title, style: theme.textTheme.titleMedium),
                        Text(
                          mention.chapterLabel?.isNotEmpty == true
                              ? mention.chapterLabel!
                              : 'Mention',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(mention.excerpt, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

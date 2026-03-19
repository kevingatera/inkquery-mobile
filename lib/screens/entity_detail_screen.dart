import 'dart:convert';

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
      appBar: AppBar(title: const Text('Entity')),
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
          final aliases = _parseAliases(entity.aliasesJson);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              InkPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Text(entity.name, style: theme.textTheme.headlineMedium),
                    Text(
                      [
                        entity.kind,
                        '${entity.mentions.length} mentions',
                        if (aliases.isNotEmpty) '${aliases.length} aliases',
                      ].join('  ·  '),
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(entity.summary, style: theme.textTheme.bodyMedium),
                    if (aliases.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: aliases
                            .map((alias) => Chip(label: Text(alias)))
                            .toList(),
                      ),
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
                      spacing: 6,
                      children: [
                        Text(mention.title, style: theme.textTheme.titleMedium),
                        Text(
                          [
                            if (mention.chapterLabel?.isNotEmpty == true) mention.chapterLabel!,
                            if (mention.publishedDate?.isNotEmpty == true) mention.publishedDate!,
                          ].join('  ·  ').isEmpty
                              ? 'Mention'
                              : [
                                  if (mention.chapterLabel?.isNotEmpty == true) mention.chapterLabel!,
                                  if (mention.publishedDate?.isNotEmpty == true) mention.publishedDate!,
                                ].join('  ·  '),
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

  List<String> _parseAliases(String raw) {
    if (raw.trim().isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().where((value) => value.trim().isNotEmpty).toList();
      }
    } catch (_) {}
    return [raw];
  }
}

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
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Entity'),
      ),
      body: FutureBuilder<EntityDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: scheme.primary),
                  const SizedBox(height: 16),
                  Text('Loading entity...', style: theme.textTheme.bodySmall),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 28,
                        color: scheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load entity',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${snapshot.error}',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final entity = snapshot.data!;
          final aliases = _parseAliases(entity.aliasesJson);
          final (kindColor, kindBg) = _kindColors(entity.kind, scheme);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // --- Hero header ---
              _EntityHeroHeader(
                entity: entity,
                kindColor: kindColor,
                kindBg: kindBg,
              ),

              const SizedBox(height: 16),

              // --- Aliases ---
              if (aliases.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.tag_rounded,
                  label: 'Aliases',
                  count: aliases.length,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: aliases.map((alias) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kindBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: kindColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        alias,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: kindColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // --- Mentions section ---
              if (entity.mentions.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.menu_book_rounded,
                  label: 'Mentions',
                  count: entity.mentions.length,
                ),
                const SizedBox(height: 10),
                ...entity.mentions.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MentionCard(
                      mention: entry.value,
                      index: entry.key + 1,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 48),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 36,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No mentions found',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
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
        return decoded
            .whereType<String>()
            .where((value) => value.trim().isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [raw];
  }

  (Color, Color) _kindColors(String kind, ColorScheme scheme) {
    return switch (kind.toLowerCase()) {
      'character' || 'person' => (scheme.primary, scheme.primaryContainer),
      'place' || 'location' => (scheme.secondary, scheme.secondaryContainer),
      'faction' ||
      'organization' ||
      'group' => (scheme.tertiary, scheme.tertiaryContainer),
      _ => (scheme.onSurfaceVariant, scheme.surfaceContainerLow),
    };
  }
}

// ---------------------------------------------------------------------------
// Hero header — kind icon, name, kind badge, summary
// ---------------------------------------------------------------------------

class _EntityHeroHeader extends StatelessWidget {
  const _EntityHeroHeader({
    required this.entity,
    required this.kindColor,
    required this.kindBg,
  });

  final EntityDetail entity;
  final Color kindColor;
  final Color kindBg;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kind icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: kindBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_kindIcon(entity.kind), size: 26, color: kindColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entity.name, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Kind badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: kindBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            entity.kind,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: kindColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Mention count
                        Icon(
                          Icons.menu_book_rounded,
                          size: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${entity.mentions.length} mentions',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (entity.summary.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: kindColor.withValues(alpha: 0.3),
                    width: 2.5,
                  ),
                ),
              ),
              child: SelectableText(
                entity.summary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.55,
                  color: scheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _kindIcon(String kind) {
    return switch (kind.toLowerCase()) {
      'character' || 'person' => Icons.person_outline,
      'place' || 'location' => Icons.place_outlined,
      'faction' || 'organization' || 'group' => Icons.groups_outlined,
      'concept' || 'idea' || 'theme' => Icons.psychology_outlined,
      'event' => Icons.event_outlined,
      'item' || 'object' || 'artifact' => Icons.category_outlined,
      _ => Icons.label_outline,
    };
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label, this.count});

  final IconData icon;
  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.titleMedium),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mention card
// ---------------------------------------------------------------------------

class _MentionCard extends StatelessWidget {
  const _MentionCard({required this.mention, required this.index});

  final EntityMention mention;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final metaParts = <String>[
      if (mention.chapterLabel?.isNotEmpty == true) mention.chapterLabel!,
      if (mention.publishedDate?.isNotEmpty == true) mention.publishedDate!,
    ];
    final metaText = metaParts.isNotEmpty ? metaParts.join(' · ') : null;

    return InkPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book icon / index
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              size: 17,
              color: scheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mention.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (metaText != null) ...[
                  const SizedBox(height: 2),
                  Text(metaText, style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: scheme.secondary.withValues(alpha: 0.3),
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: SelectableText(
                    mention.excerpt,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.55,
                      fontStyle: FontStyle.italic,
                      color: scheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

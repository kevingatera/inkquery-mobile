import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/entity_models.dart';
import '../providers/entities_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/ink_panel.dart';
import 'entity_detail_screen.dart';

class EntitiesScreen extends StatefulWidget {
  const EntitiesScreen({super.key});

  @override
  State<EntitiesScreen> createState() => _EntitiesScreenState();
}

class _EntitiesScreenState extends State<EntitiesScreen> {
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EntitiesController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_queryController.text != controller.query) {
      _queryController.value = TextEditingValue(
        text: controller.query,
        selection: TextSelection.collapsed(offset: controller.query.length),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadEntities,
      color: scheme.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          // --- Search + filters ---
          InkPanel(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        onChanged: controller.setQuery,
                        onSubmitted: (_) => controller.loadEntities(),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search entities',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: controller.loadEntities,
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Search'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Kind filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        avatar: Icon(
                          Icons.select_all_rounded,
                          size: 16,
                          color: controller.selectedKind.isEmpty
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                        label: const Text('All'),
                        selected: controller.selectedKind.isEmpty,
                        onSelected: (_) => controller.setKind(''),
                      ),
                      ...controller.kinds.map(
                        (kind) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            avatar: Icon(
                              _kindIcon(kind),
                              size: 16,
                              color: controller.selectedKind == kind
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurfaceVariant,
                            ),
                            label: Text(kind),
                            selected: controller.selectedKind == kind,
                            onSelected: (_) => controller.setKind(kind),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.hub_outlined,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${controller.items.length} results${controller.selectedKind.isNotEmpty ? ' in ${controller.selectedKind}' : ''}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const Spacer(),
                    if (controller.isLoading)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: scheme.primary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // --- Error ---
          if (controller.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
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
                    Icon(Icons.error_outline, size: 16, color: scheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // --- Loading ---
          if (controller.isLoading && controller.items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          // --- Empty ---
          else if (controller.items.isEmpty)
            const SizedBox(
              height: 320,
              child: EmptyState(
                icon: Icons.hub_outlined,
                title: 'No entities yet',
                message:
                    'Try a broader query or refresh after more books have been ingested.',
              ),
            )
          // --- Entity cards ---
          else
            ...controller.items.map(
              (entity) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EntityCard(entity: entity),
              ),
            ),
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
// Entity card
// ---------------------------------------------------------------------------

class _EntityCard extends StatelessWidget {
  const _EntityCard({required this.entity});

  final EntitySummary entity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final kindIcon = _kindIcon(entity.kind);
    final (kindColor, kindBg) = _kindColors(entity.kind, scheme);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EntityDetailScreen(entityId: entity.id),
          ),
        );
      },
      child: InkPanel(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kind icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kindBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(kindIcon, size: 20, color: kindColor),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entity.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kindBg,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          entity.kind,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kindColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entity.summary,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
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

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

    if (_queryController.text != controller.query) {
      _queryController.value = TextEditingValue(
        text: controller.query,
        selection: TextSelection.collapsed(offset: controller.query.length),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadEntities,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          InkPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text('Entity graph', style: theme.textTheme.titleLarge),
                Text(
                  'Search characters, houses, locations, and concepts extracted from the books.',
                  style: theme.textTheme.bodyMedium,
                ),
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
                    FilledButton(
                      onPressed: controller.loadEntities,
                      child: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: controller.selectedKind.isEmpty,
                      onSelected: (_) => controller.setKind(''),
                    ),
                    ...controller.kinds.map(
                      (kind) => FilterChip(
                        label: Text(kind),
                        selected: controller.selectedKind == kind,
                        onSelected: (_) => controller.setKind(kind),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (controller.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                controller.errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          if (controller.isLoading && controller.items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.items.isEmpty)
            const SizedBox(
              height: 420,
              child: EmptyState(
                title: 'No entities yet',
                message: 'Try a broader query or refresh after more books have been ingested.',
              ),
            )
          else
            ...controller.items.map((entity) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _EntityCard(entity: entity),
                )),
        ],
      ),
    );
  }
}

class _EntityCard extends StatelessWidget {
  const _EntityCard({required this.entity});

  final EntitySummary entity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EntityDetailScreen(entityId: entity.id),
          ),
        );
      },
      child: InkPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(entity.name, style: theme.textTheme.titleLarge),
                ),
                Chip(label: Text(entity.kind)),
              ],
            ),
            Text(entity.summary, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

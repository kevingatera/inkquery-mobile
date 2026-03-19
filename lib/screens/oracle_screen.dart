import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_models.dart';
import '../providers/chat_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/ink_panel.dart';

class OracleScreen extends StatefulWidget {
  const OracleScreen({super.key});

  @override
  State<OracleScreen> createState() => _OracleScreenState();
}

class _OracleScreenState extends State<OracleScreen> {
  late final TextEditingController _composerController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _composerController = TextEditingController();
  }

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatController>();
    final theme = Theme.of(context);

    if (_composerController.text != controller.draft) {
      _composerController.value = TextEditingValue(
        text: controller.draft,
        selection: TextSelection.collapsed(offset: controller.draft.length),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          InkPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.messages.isEmpty
                            ? 'Start a query'
                            : '${controller.messages.where((entry) => entry.isUser).length} questions in this session',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (controller.stage != null)
                      Text(
                        _stageLabel(controller.stage!),
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
                if (controller.suggestions.isNotEmpty && controller.messages.isEmpty)
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.suggestions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final suggestion = controller.suggestions[index];
                        return ActionChip(
                          label: Text(suggestion),
                          onPressed: () => _sendSuggested(context, suggestion),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: controller.messages.isEmpty
                ? EmptyState(
                    title: 'No conversation yet',
                    message: controller.suggestions.isEmpty
                        ? 'Ask the oracle about characters, places, missing sidebooks, or first appearances.'
                        : 'Start with one of the server suggestions or ask your own question.',
                    action: controller.suggestions.isEmpty
                        ? null
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: controller.suggestions
                                .map(
                                  (suggestion) => ActionChip(
                                    label: Text(suggestion),
                                    onPressed: () => _sendSuggested(context, suggestion),
                                  ),
                                )
                                .toList(),
                          ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    itemCount: controller.messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = controller.messages[index];
                      return _MessageBubble(entry: entry);
                    },
                  ),
          ),
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              controller.errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 10),
          InkPanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _composerController,
                  minLines: 1,
                  maxLines: 5,
                  onChanged: controller.updateDraft,
                  onSubmitted: controller.isSending ? null : (_) => _send(context),
                  decoration: const InputDecoration(
                    hintText: 'Ask about a character, place, faction, or source passage.',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.stage == null
                            ? 'Grounded answers only'
                            : 'Working: ${_stageLabel(controller.stage!)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    FilledButton(
                      onPressed: controller.isSending ? null : () => _send(context),
                      child: const Text('Send'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(BuildContext context) async {
    final controller = context.read<ChatController>();
    final text = _composerController.text;
    await controller.sendMessage(text);
  }

  Future<void> _sendSuggested(BuildContext context, String suggestion) async {
    _composerController.text = suggestion;
    await context.read<ChatController>().sendMessage(suggestion);
  }

  String _stageLabel(ChatStage stage) {
    return switch (stage) {
      ChatStage.retrieving => 'Retrieving',
      ChatStage.selecting => 'Selecting',
      ChatStage.synthesizing => 'Synthesizing',
    };
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.entry});

  final ConversationEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = entry.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = entry.isUser ? theme.colorScheme.primary : theme.colorScheme.surface;
    final textColor = entry.isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final label = entry.isUser ? 'You' : 'Oracle';
    final meta = [
      if (!entry.isUser && entry.responseMode != null) entry.responseMode,
      if (!entry.isUser && entry.citations.isNotEmpty) '${entry.citations.length} sources',
    ].whereType<String>().join('  ·  ');

    return Column(
      crossAxisAlignment: alignment,
      spacing: 8,
      children: [
        Text(
          meta.isEmpty ? label : '$label  ·  $meta',
          style: theme.textTheme.bodySmall,
        ),
        Align(
          alignment: entry.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bubbleColor,
                border: entry.isUser ? null : Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  entry.text.isEmpty && !entry.isUser ? '...' : entry.text,
                  style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
                ),
              ),
            ),
          ),
        ),
        if (!entry.isUser && entry.citations.isNotEmpty)
          Column(
            children: entry.citations
                .map(
                  (citation) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkPanel(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Text(citation.title, style: theme.textTheme.titleMedium),
                          Text(citation.locator, style: theme.textTheme.bodySmall),
                          Text(citation.note, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        if (!entry.isUser && entry.actionHints.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entry.actionHints
                .map(
                  (hint) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${hint.label}: ${hint.detail}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

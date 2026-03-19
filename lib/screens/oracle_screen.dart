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
    final scheme = theme.colorScheme;

    if (_composerController.text != controller.draft) {
      _composerController.value = TextEditingValue(
        text: controller.draft,
        selection: TextSelection.collapsed(offset: controller.draft.length),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });

    final questionCount = controller.messages
        .where((entry) => entry.isUser)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // --- Session header ---
          InkPanel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.messages.isEmpty
                            ? 'Start a query'
                            : '$questionCount question${questionCount == 1 ? '' : 's'} in this session',
                        style: theme.textTheme.titleMedium,
                      ),
                      if (controller.stage != null) ...[
                        const SizedBox(height: 6),
                        _StageIndicator(stage: controller.stage!),
                      ],
                    ],
                  ),
                ),
                if (controller.messages.isNotEmpty)
                  IconButton(
                    onPressed: null, // could wire up clear session
                    icon: Icon(
                      Icons.restart_alt_rounded,
                      color: scheme.onSurfaceVariant,
                      size: 20,
                    ),
                    tooltip: 'New session',
                  ),
              ],
            ),
          ),

          // --- Suggestion chips (only when empty) ---
          if (controller.suggestions.isNotEmpty &&
              controller.messages.isEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: controller.suggestions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final suggestion = controller.suggestions[index];
                  return ActionChip(
                    label: Text(
                      suggestion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () => _sendSuggested(context, suggestion),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),

          // --- Message list or empty state ---
          Expanded(
            child: controller.messages.isEmpty
                ? EmptyState(
                    icon: Icons.auto_awesome_outlined,
                    title: 'No conversation yet',
                    message: controller.suggestions.isEmpty
                        ? 'Ask the oracle about characters, places, missing sidebooks, or first appearances.'
                        : 'Start with one of the suggestions above or ask your own question.',
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: controller.messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final entry = controller.messages[index];
                      return _MessageBubble(
                        entry: entry,
                        isStreaming:
                            controller.isSending &&
                            !entry.isUser &&
                            index == controller.messages.length - 1,
                      );
                    },
                  ),
          ),

          // --- Error banner ---
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          ],

          const SizedBox(height: 10),

          // --- Composer ---
          InkPanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _composerController,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onChanged: controller.updateDraft,
                  onSubmitted: controller.isSending
                      ? null
                      : (_) => _send(context),
                  decoration: InputDecoration(
                    hintText:
                        'Ask about a character, place, faction, or passage...',
                    suffixIcon: IconButton(
                      onPressed: controller.isSending
                          ? null
                          : () => _send(context),
                      icon: Icon(
                        Icons.send_rounded,
                        color: controller.isSending
                            ? scheme.outline
                            : scheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        controller.stage == null
                            ? 'Grounded answers only'
                            : 'Working: ${_stageLabel(controller.stage!)}',
                        style: theme.textTheme.bodySmall,
                      ),
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
      ChatStage.retrieving => 'Retrieving passages',
      ChatStage.selecting => 'Selecting sources',
      ChatStage.synthesizing => 'Synthesizing answer',
    };
  }
}

// ---------------------------------------------------------------------------
// Stage progress indicator
// ---------------------------------------------------------------------------

class _StageIndicator extends StatelessWidget {
  const _StageIndicator({required this.stage});

  final ChatStage stage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stages = ChatStage.values;
    final currentIndex = stages.indexOf(stage);

    return Row(
      children: [
        for (int i = 0; i < stages.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: 16,
                child: Divider(
                  color: i <= currentIndex
                      ? scheme.primary
                      : scheme.outlineVariant,
                  thickness: 1.5,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: i <= currentIndex
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: i <= currentIndex
                    ? scheme.primary.withValues(alpha: 0.3)
                    : scheme.outlineVariant,
              ),
            ),
            child: Text(
              _label(stages[i]),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: i <= currentIndex
                    ? scheme.primary
                    : scheme.onSurfaceVariant,
                fontWeight: i == currentIndex
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _label(ChatStage s) => switch (s) {
    ChatStage.retrieving => 'Retrieve',
    ChatStage.selecting => 'Select',
    ChatStage.synthesizing => 'Synthesize',
  };
}

// ---------------------------------------------------------------------------
// Message bubble
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.entry, this.isStreaming = false});

  final ConversationEntry entry;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isUser = entry.isUser;

    final bubbleColor = isUser ? scheme.primary : scheme.surface;
    final textColor = isUser ? scheme.onPrimary : scheme.onSurface;

    return Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        // Label row
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isUser) ...[
                Icon(Icons.auto_awesome, size: 12, color: scheme.primary),
                const SizedBox(width: 4),
              ],
              Text(
                _buildLabel(),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Bubble
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bubbleColor,
                border: isUser
                    ? null
                    : Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: entry.text.isEmpty && !isUser
                    ? _TypingIndicator(color: scheme.onSurfaceVariant)
                    : SelectableText(
                        entry.text,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: textColor,
                        ),
                      ),
              ),
            ),
          ),
        ),

        // Citations
        if (!isUser && entry.citations.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...entry.citations.map(
            (citation) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _CitationCard(citation: citation),
            ),
          ),
        ],

        // Action hints
        if (!isUser && entry.actionHints.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: entry.actionHints.map((hint) {
              return _ActionHintChip(hint: hint);
            }).toList(),
          ),
        ],
      ],
    );
  }

  String _buildLabel() {
    if (entry.isUser) return 'You';
    final parts = <String>['Oracle'];
    if (entry.responseMode != null) parts.add(entry.responseMode!);
    if (entry.citations.isNotEmpty) {
      parts.add(
        '${entry.citations.length} source${entry.citations.length == 1 ? '' : 's'}',
      );
    }
    return parts.join('  ·  ');
  }
}

// ---------------------------------------------------------------------------
// Typing indicator
// ---------------------------------------------------------------------------

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.color});

  final Color color;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = (_controller.value - i * 0.15).clamp(0.0, 1.0);
              final y = -4.0 * (1.0 - (2.0 * t - 1.0).abs());
              return Container(
                margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                child: Transform.translate(
                  offset: Offset(0, y),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(
                        alpha: 0.3 + 0.5 * (1.0 - (2.0 * t - 1.0).abs()),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Citation card
// ---------------------------------------------------------------------------

class _CitationCard extends StatelessWidget {
  const _CitationCard({required this.citation});

  final ChatCitation citation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                Icons.format_quote_rounded,
                size: 14,
                color: scheme.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(citation.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    citation.locator,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (citation.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      citation.note,
                      style: theme.textTheme.bodySmall,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action hint chip
// ---------------------------------------------------------------------------

class _ActionHintChip extends StatelessWidget {
  const _ActionHintChip({required this.hint});

  final ChatActionHint hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final icon = switch (hint.type) {
      'missing_title' => Icons.library_add_outlined,
      'retry' => Icons.replay_rounded,
      _ => Icons.lightbulb_outline_rounded,
    };

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        // If there's a retry question, send it
        if (hint.retryQuestion != null) {
          context.read<ChatController>().sendMessage(hint.retryQuestion!);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${hint.label}: ${hint.detail}',
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

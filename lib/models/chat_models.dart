enum ChatStage { retrieving, selecting, synthesizing }

class ChatCitation {
  const ChatCitation({
    required this.title,
    required this.note,
    required this.locator,
  });

  final String title;
  final String note;
  final String locator;

  factory ChatCitation.fromJson(Map<String, dynamic> json) {
    return ChatCitation(
      title: json['title'] as String? ?? '',
      note: json['note'] as String? ?? '',
      locator: json['locator'] as String? ?? '',
    );
  }
}

class ChatActionHint {
  const ChatActionHint({
    required this.type,
    required this.label,
    required this.detail,
    this.requestTerm,
    this.suggestedTitles = const [],
    this.retryQuestion,
  });

  final String type;
  final String label;
  final String detail;
  final String? requestTerm;
  final List<String> suggestedTitles;
  final String? retryQuestion;

  factory ChatActionHint.fromJson(Map<String, dynamic> json) {
    return ChatActionHint(
      type: json['type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      requestTerm: json['request_term'] as String?,
      suggestedTitles:
          (json['suggested_titles'] as List<dynamic>? ?? const []).cast<String>(),
      retryQuestion: json['retry_question'] as String?,
    );
  }
}

class ChatResponsePayload {
  const ChatResponsePayload({
    required this.answer,
    required this.responseMode,
    required this.sourceCount,
    required this.citations,
    required this.actionHints,
  });

  final String answer;
  final String responseMode;
  final int sourceCount;
  final List<ChatCitation> citations;
  final List<ChatActionHint> actionHints;

  factory ChatResponsePayload.fromJson(Map<String, dynamic> json) {
    return ChatResponsePayload(
      answer: json['answer'] as String? ?? '',
      responseMode: json['response_mode'] as String? ?? 'empty',
      sourceCount: (json['source_count'] as num?)?.toInt() ?? 0,
      citations: (json['citations'] as List<dynamic>? ?? const [])
          .map((item) => ChatCitation.fromJson(item as Map<String, dynamic>))
          .toList(),
      actionHints: (json['action_hints'] as List<dynamic>? ?? const [])
          .map((item) => ChatActionHint.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ConversationEntry {
  const ConversationEntry({
    required this.id,
    required this.isUser,
    required this.text,
    this.createdAt,
    this.citations = const [],
    this.actionHints = const [],
    this.responseMode,
  });

  final String id;
  final bool isUser;
  final String text;
  final DateTime? createdAt;
  final List<ChatCitation> citations;
  final List<ChatActionHint> actionHints;
  final String? responseMode;

  ConversationEntry copyWith({
    String? text,
    List<ChatCitation>? citations,
    List<ChatActionHint>? actionHints,
    String? responseMode,
  }) {
    return ConversationEntry(
      id: id,
      isUser: isUser,
      text: text ?? this.text,
      createdAt: createdAt,
      citations: citations ?? this.citations,
      actionHints: actionHints ?? this.actionHints,
      responseMode: responseMode ?? this.responseMode,
    );
  }
}

sealed class ChatStreamEvent {
  const ChatStreamEvent();
}

class ChatStageEvent extends ChatStreamEvent {
  const ChatStageEvent(this.stage);

  final ChatStage stage;
}

class ChatAnswerDeltaEvent extends ChatStreamEvent {
  const ChatAnswerDeltaEvent(this.delta);

  final String delta;
}

class ChatCompleteEvent extends ChatStreamEvent {
  const ChatCompleteEvent(this.payload);

  final ChatResponsePayload payload;
}

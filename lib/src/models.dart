class AuthCapabilities {
  const AuthCapabilities({
    required this.authRequired,
    required this.localEnabled,
    required this.oidcEnabled,
    required this.oidcLabel,
  });

  final bool authRequired;
  final bool localEnabled;
  final bool oidcEnabled;
  final String oidcLabel;

  factory AuthCapabilities.fromJson(Map<String, dynamic> json) {
    final local = json['local'] as Map<String, dynamic>? ?? const {};
    final oidc = json['oidc'] as Map<String, dynamic>? ?? const {};
    return AuthCapabilities(
      authRequired: json['auth_required'] == true,
      localEnabled: local['enabled'] == true,
      oidcEnabled: oidc['enabled'] == true,
      oidcLabel: (oidc['label'] as String?) ?? 'Continue with OpenID',
    );
  }
}

class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.username,
    required this.role,
    this.email,
  });

  final int id;
  final String username;
  final String role;
  final String? email;

  bool get isAdmin => role == 'admin';

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      email: json['email'] as String?,
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final CurrentUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: CurrentUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class BookItem {
  const BookItem({
    required this.id,
    required this.title,
    required this.authorName,
    required this.seriesName,
    required this.passageCount,
    required this.fileFormat,
    required this.sourcePath,
    required this.status,
  });

  final int id;
  final String title;
  final String? authorName;
  final String? seriesName;
  final int passageCount;
  final String? fileFormat;
  final String? sourcePath;
  final String status;

  factory BookItem.fromJson(Map<String, dynamic> json) {
    return BookItem(
      id: json['id'] as int,
      title: json['title'] as String,
      authorName: json['author_name'] as String?,
      seriesName: json['series_name'] as String?,
      passageCount: json['passage_count'] as int? ?? 0,
      fileFormat: json['file_format'] as String?,
      sourcePath: json['source_path'] as String?,
      status: (json['status'] as String?) ?? 'unknown',
    );
  }
}

class PassageSample {
  const PassageSample({
    required this.id,
    required this.excerpt,
    this.chapterLabel,
  });

  final int id;
  final String excerpt;
  final String? chapterLabel;

  factory PassageSample.fromJson(Map<String, dynamic> json) {
    return PassageSample(
      id: json['id'] as int,
      excerpt: json['excerpt'] as String,
      chapterLabel: json['chapter_label'] as String?,
    );
  }
}

class BookDetail {
  const BookDetail({
    required this.id,
    required this.title,
    required this.authorName,
    required this.seriesName,
    required this.passageCount,
    required this.sourcePath,
    required this.fileFormat,
    required this.samplePassages,
  });

  final int id;
  final String title;
  final String? authorName;
  final String? seriesName;
  final int passageCount;
  final String? sourcePath;
  final String? fileFormat;
  final List<PassageSample> samplePassages;

  factory BookDetail.fromJson(Map<String, dynamic> json) {
    final samples = json['sample_passages'] as List<dynamic>? ?? const [];
    return BookDetail(
      id: json['id'] as int,
      title: json['title'] as String,
      authorName: json['author_name'] as String?,
      seriesName: json['series_name'] as String?,
      passageCount: json['passage_count'] as int? ?? 0,
      sourcePath: json['source_path'] as String?,
      fileFormat: json['file_format'] as String?,
      samplePassages: samples
          .map((item) => PassageSample.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EntityItem {
  const EntityItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.summary,
  });

  final int id;
  final String name;
  final String kind;
  final String summary;

  factory EntityItem.fromJson(Map<String, dynamic> json) {
    return EntityItem(
      id: json['id'] as int,
      name: json['name'] as String,
      kind: json['kind'] as String,
      summary: (json['summary'] as String?) ?? '',
    );
  }
}

class EntityMention {
  const EntityMention({
    required this.id,
    required this.title,
    required this.excerpt,
    this.chapterLabel,
  });

  final int id;
  final String title;
  final String excerpt;
  final String? chapterLabel;

  factory EntityMention.fromJson(Map<String, dynamic> json) {
    return EntityMention(
      id: json['id'] as int,
      title: json['title'] as String,
      excerpt: json['excerpt'] as String,
      chapterLabel: json['chapter_label'] as String?,
    );
  }
}

class EntityDetail {
  const EntityDetail({
    required this.id,
    required this.name,
    required this.kind,
    required this.summary,
    required this.mentions,
  });

  final int id;
  final String name;
  final String kind;
  final String summary;
  final List<EntityMention> mentions;

  factory EntityDetail.fromJson(Map<String, dynamic> json) {
    final mentions = json['mentions'] as List<dynamic>? ?? const [];
    return EntityDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      kind: json['kind'] as String,
      summary: (json['summary'] as String?) ?? '',
      mentions: mentions
          .map((item) => EntityMention.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

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
      title: json['title'] as String,
      note: json['note'] as String,
      locator: json['locator'] as String,
    );
  }
}

class ChatResponse {
  const ChatResponse({
    required this.answer,
    required this.responseMode,
    required this.sourceCount,
    required this.citations,
  });

  final String answer;
  final String responseMode;
  final int sourceCount;
  final List<ChatCitation> citations;

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final citations = json['citations'] as List<dynamic>? ?? const [];
    return ChatResponse(
      answer: (json['answer'] as String?) ?? '',
      responseMode: (json['response_mode'] as String?) ?? 'empty',
      sourceCount: json['source_count'] as int? ?? 0,
      citations: citations
          .map((item) => ChatCitation.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChatExchange {
  const ChatExchange({
    required this.question,
    required this.answer,
    required this.responseMode,
    required this.citations,
  });

  final String question;
  final String answer;
  final String responseMode;
  final List<ChatCitation> citations;
}

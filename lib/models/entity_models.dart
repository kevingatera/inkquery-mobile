class EntitySummary {
  const EntitySummary({
    required this.id,
    required this.name,
    required this.kind,
    required this.summary,
  });

  final int id;
  final String name;
  final String kind;
  final String summary;

  factory EntitySummary.fromJson(Map<String, dynamic> json) {
    return EntitySummary(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
    );
  }
}

class EntityMention {
  const EntityMention({
    required this.id,
    required this.chapterLabel,
    required this.excerpt,
    required this.title,
    required this.publishedDate,
  });

  final int id;
  final String? chapterLabel;
  final String excerpt;
  final String title;
  final String? publishedDate;

  factory EntityMention.fromJson(Map<String, dynamic> json) {
    return EntityMention(
      id: (json['id'] as num).toInt(),
      chapterLabel: json['chapter_label'] as String?,
      excerpt: json['excerpt'] as String? ?? '',
      title: json['title'] as String? ?? '',
      publishedDate: json['published_date'] as String?,
    );
  }
}

class EntityDetail {
  const EntityDetail({
    required this.id,
    required this.name,
    required this.kind,
    required this.summary,
    required this.aliasesJson,
    required this.mentions,
  });

  final int id;
  final String name;
  final String kind;
  final String summary;
  final String aliasesJson;
  final List<EntityMention> mentions;

  factory EntityDetail.fromJson(Map<String, dynamic> json) {
    return EntityDetail(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      aliasesJson: json['aliases_json'] as String? ?? '',
      mentions: (json['mentions'] as List<dynamic>? ?? const [])
          .map((item) => EntityMention.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

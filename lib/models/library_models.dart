class BookListItem {
  const BookListItem({
    required this.id,
    required this.title,
    required this.seriesName,
    required this.authorName,
    required this.publishedDate,
    required this.status,
    required this.sourceName,
    required this.sourcePath,
    required this.fileFormat,
    required this.passageCount,
  });

  final int id;
  final String title;
  final String? seriesName;
  final String? authorName;
  final String? publishedDate;
  final String status;
  final String? sourceName;
  final String? sourcePath;
  final String? fileFormat;
  final int passageCount;

  factory BookListItem.fromJson(Map<String, dynamic> json) {
    return BookListItem(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      seriesName: json['series_name'] as String?,
      authorName: json['author_name'] as String?,
      publishedDate: json['published_date'] as String?,
      status: json['status'] as String? ?? 'unknown',
      sourceName: json['source_name'] as String?,
      sourcePath: json['source_path'] as String?,
      fileFormat: json['file_format'] as String?,
      passageCount: (json['passage_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class SamplePassage {
  const SamplePassage({
    required this.id,
    required this.chapterLabel,
    required this.excerpt,
  });

  final int id;
  final String? chapterLabel;
  final String excerpt;

  factory SamplePassage.fromJson(Map<String, dynamic> json) {
    return SamplePassage(
      id: (json['id'] as num).toInt(),
      chapterLabel: json['chapter_label'] as String?,
      excerpt: json['excerpt'] as String? ?? '',
    );
  }
}

class BookDetail {
  const BookDetail({
    required this.id,
    required this.title,
    required this.seriesName,
    required this.authorName,
    required this.publishedDate,
    required this.status,
    required this.sourceName,
    required this.sourcePath,
    required this.fileFormat,
    required this.passageCount,
    required this.samplePassages,
  });

  final int id;
  final String title;
  final String? seriesName;
  final String? authorName;
  final String? publishedDate;
  final String status;
  final String? sourceName;
  final String? sourcePath;
  final String? fileFormat;
  final int passageCount;
  final List<SamplePassage> samplePassages;

  factory BookDetail.fromJson(Map<String, dynamic> json) {
    return BookDetail(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      seriesName: json['series_name'] as String?,
      authorName: json['author_name'] as String?,
      publishedDate: json['published_date'] as String?,
      status: json['status'] as String? ?? 'unknown',
      sourceName: json['source_name'] as String?,
      sourcePath: json['source_path'] as String?,
      fileFormat: json['file_format'] as String?,
      passageCount: (json['passage_count'] as num?)?.toInt() ?? 0,
      samplePassages: (json['sample_passages'] as List<dynamic>? ?? const [])
          .map((item) => SamplePassage.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

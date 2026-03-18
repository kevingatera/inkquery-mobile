class DashboardCounts {
  const DashboardCounts({
    required this.books,
    required this.passages,
    required this.entities,
  });

  final int books;
  final int passages;
  final int entities;

  factory DashboardCounts.fromJson(Map<String, dynamic> json) {
    return DashboardCounts(
      books: (json['books'] as num?)?.toInt() ?? 0,
      passages: (json['passages'] as num?)?.toInt() ?? 0,
      entities: (json['entities'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardConnector {
  const DashboardConnector({
    required this.name,
    required this.status,
    required this.detail,
  });

  final String name;
  final String status;
  final String detail;

  factory DashboardConnector.fromJson(Map<String, dynamic> json) {
    return DashboardConnector(
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.counts,
    required this.connectors,
    required this.workflow,
  });

  final DashboardCounts counts;
  final List<DashboardConnector> connectors;
  final List<String> workflow;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      counts: DashboardCounts.fromJson(json['counts'] as Map<String, dynamic>),
      connectors: (json['connectors'] as List<dynamic>? ?? const [])
          .map((item) => DashboardConnector.fromJson(item as Map<String, dynamic>))
          .toList(),
      workflow: (json['workflow'] as List<dynamic>? ?? const []).cast<String>(),
    );
  }
}

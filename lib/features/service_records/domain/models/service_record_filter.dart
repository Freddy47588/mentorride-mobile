enum ServiceRecordFilterType { all, month, year }

class ServiceRecordFilter {
  const ServiceRecordFilter({
    required this.type,
    required this.anchor,
    this.query = '',
    this.minimumCost,
    this.maximumCost,
  });

  final ServiceRecordFilterType type;
  final DateTime anchor;
  final String query;
  final int? minimumCost;
  final int? maximumCost;

  bool get hasSearchQuery => query.trim().isNotEmpty;

  bool get hasCostRange => minimumCost != null || maximumCost != null;

  bool get hasActiveFilter =>
      type != ServiceRecordFilterType.all || hasSearchQuery || hasCostRange;

  ServiceRecordFilter copyWith({
    ServiceRecordFilterType? type,
    DateTime? anchor,
    String? query,
    int? minimumCost,
    int? maximumCost,
    bool clearMinimumCost = false,
    bool clearMaximumCost = false,
  }) {
    return ServiceRecordFilter(
      type: type ?? this.type,
      anchor: anchor ?? this.anchor,
      query: query ?? this.query,
      minimumCost: clearMinimumCost ? null : minimumCost ?? this.minimumCost,
      maximumCost: clearMaximumCost ? null : maximumCost ?? this.maximumCost,
    );
  }
}

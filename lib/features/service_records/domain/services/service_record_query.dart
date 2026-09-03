import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_records/domain/models/service_record_filter.dart';

abstract final class ServiceRecordQuery {
  static List<ServiceRecord> apply({
    required Iterable<ServiceRecord> records,
    required ServiceRecordFilter filter,
  }) {
    final queryTerms = _normalize(
      filter.query,
    ).split(' ').where((term) => term.isNotEmpty).toList(growable: false);

    return records
        .where((record) {
          return _matchesPeriod(record, filter) &&
              _matchesCost(record, filter) &&
              _matchesQuery(record, queryTerms);
        })
        .toList(growable: false);
  }

  static bool _matchesPeriod(ServiceRecord record, ServiceRecordFilter filter) {
    final serviceDate = record.serviceDate.toLocal();
    final anchor = filter.anchor.toLocal();
    return switch (filter.type) {
      ServiceRecordFilterType.all => true,
      ServiceRecordFilterType.month =>
        serviceDate.year == anchor.year && serviceDate.month == anchor.month,
      ServiceRecordFilterType.year => serviceDate.year == anchor.year,
    };
  }

  static bool _matchesCost(ServiceRecord record, ServiceRecordFilter filter) {
    final minimum = filter.minimumCost;
    if (minimum != null && record.totalCost < minimum) return false;

    final maximum = filter.maximumCost;
    if (maximum != null && record.totalCost > maximum) return false;
    return true;
  }

  static bool _matchesQuery(ServiceRecord record, List<String> terms) {
    if (terms.isEmpty) return true;

    final searchableText = _normalize(
      [
        record.workshop,
        record.notes,
        ...record.items.map((item) => item.name),
      ].join(' '),
    );
    return terms.every(searchableText.contains);
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

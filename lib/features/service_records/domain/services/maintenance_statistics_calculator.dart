import 'package:mentorride/features/service_records/domain/models/maintenance_statistics.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';

abstract final class MaintenanceStatisticsCalculator {
  static MaintenanceStatistics calculate(Iterable<ServiceRecord> records) {
    var serviceCount = 0;
    var totalCost = 0;
    final components = <String, _MutableComponentStatistic>{};

    for (final record in records) {
      serviceCount++;
      totalCost += record.totalCost;

      for (final item in record.items) {
        final displayName = _collapseWhitespace(item.name);
        if (displayName.isEmpty) continue;

        final key = displayName.toLowerCase();
        final component = components.putIfAbsent(
          key,
          () => _MutableComponentStatistic(displayName),
        );
        component.occurrenceCount += 1;
        component.totalCost += item.cost;
      }
    }

    final componentStatistics =
        components.values
            .map(
              (component) => ComponentMaintenanceStatistic(
                name: component.name,
                occurrenceCount: component.occurrenceCount,
                totalCost: component.totalCost,
              ),
            )
            .toList(growable: false)
          ..sort(_compareComponents);

    return MaintenanceStatistics(
      totalCost: totalCost,
      averageCostPerService: serviceCount == 0
          ? 0
          : (totalCost / serviceCount).round(),
      serviceCount: serviceCount,
      components: List.unmodifiable(componentStatistics),
    );
  }

  static int _compareComponents(
    ComponentMaintenanceStatistic left,
    ComponentMaintenanceStatistic right,
  ) {
    final occurrenceOrder = right.occurrenceCount.compareTo(
      left.occurrenceCount,
    );
    if (occurrenceOrder != 0) return occurrenceOrder;

    final costOrder = right.totalCost.compareTo(left.totalCost);
    if (costOrder != 0) return costOrder;
    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  }

  static String _collapseWhitespace(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class _MutableComponentStatistic {
  _MutableComponentStatistic(this.name);

  final String name;
  int occurrenceCount = 0;
  int totalCost = 0;
}

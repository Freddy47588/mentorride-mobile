class ComponentMaintenanceStatistic {
  const ComponentMaintenanceStatistic({
    required this.name,
    required this.occurrenceCount,
    required this.totalCost,
  });

  final String name;
  final int occurrenceCount;
  final int totalCost;
}

class MaintenanceStatistics {
  const MaintenanceStatistics({
    required this.totalCost,
    required this.averageCostPerService,
    required this.serviceCount,
    required this.components,
  });

  final int totalCost;
  final int averageCostPerService;
  final int serviceCount;
  final List<ComponentMaintenanceStatistic> components;

  ComponentMaintenanceStatistic? get mostFrequentComponent {
    return components.isEmpty ? null : components.first;
  }
}

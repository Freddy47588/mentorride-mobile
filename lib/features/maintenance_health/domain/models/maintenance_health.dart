import 'package:mentorride/core/maintenance/maintenance_preset.dart';

enum MaintenanceHealthStatus {
  safe('Aman', 100),
  approaching('Mendekati', 75),
  due('Jatuh tempo', 50),
  overdue('Terlambat', 20),
  noData('Belum ada data', null);

  const MaintenanceHealthStatus(this.label, this.score);

  final String label;
  final int? score;
}

class MaintenanceEstimate {
  const MaintenanceEstimate({this.dueOdometer, this.dueDate});

  final int? dueOdometer;
  final DateTime? dueDate;
}

class MaintenanceHealthItem {
  const MaintenanceHealthItem({
    required this.preset,
    required this.status,
    required this.description,
    this.estimate,
  });

  final MaintenancePreset preset;
  final MaintenanceHealthStatus status;
  final String description;
  final MaintenanceEstimate? estimate;
}

class MaintenanceHealthSummary {
  const MaintenanceHealthSummary({required this.items});

  final List<MaintenanceHealthItem> items;

  int count(MaintenanceHealthStatus status) {
    return items.where((item) => item.status == status).length;
  }

  int? get percentage {
    final scores = items
        .map((item) => item.status.score)
        .whereType<int>()
        .toList(growable: false);
    if (scores.isEmpty) return null;
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }
}

import 'package:mentorride/core/maintenance/maintenance_preset.dart';
import 'package:mentorride/features/maintenance_health/domain/models/maintenance_health.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';

abstract final class MaintenanceEstimator {
  static MaintenanceEstimate estimate({
    required MaintenancePreset preset,
    required ServiceRecord lastService,
  }) {
    return MaintenanceEstimate(
      dueOdometer: preset.intervalKilometers == null
          ? null
          : lastService.odometer + preset.intervalKilometers!,
      dueDate: preset.intervalMonths == null
          ? null
          : _addMonths(lastService.serviceDate, preset.intervalMonths!),
    );
  }

  static DateTime _addMonths(DateTime value, int months) {
    final monthIndex = value.month - 1 + months;
    final year = value.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = value.day > lastDay ? lastDay : value.day;
    return DateTime(year, month, day);
  }
}

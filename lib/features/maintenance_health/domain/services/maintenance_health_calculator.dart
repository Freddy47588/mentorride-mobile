import 'package:mentorride/core/maintenance/maintenance_preset.dart';
import 'package:mentorride/features/maintenance_health/domain/models/maintenance_health.dart';
import 'package:mentorride/features/maintenance_health/domain/services/maintenance_estimator.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/domain/services/service_schedule_due_calculator.dart';

abstract final class MaintenanceHealthCalculator {
  static MaintenanceHealthSummary calculate({
    required List<ServiceRecord> records,
    required List<ServiceSchedule> schedules,
    required int currentOdometer,
    required DateTime now,
    List<MaintenancePreset> presets = MaintenancePresets.values,
  }) {
    return MaintenanceHealthSummary(
      items: List.unmodifiable(
        presets.map(
          (preset) => _calculateItem(
            preset: preset,
            records: records,
            schedules: schedules,
            currentOdometer: currentOdometer,
            now: now,
          ),
        ),
      ),
    );
  }

  static MaintenanceHealthItem _calculateItem({
    required MaintenancePreset preset,
    required List<ServiceRecord> records,
    required List<ServiceSchedule> schedules,
    required int currentOdometer,
    required DateTime now,
  }) {
    final relevantRecords =
        records
            .where(
              (record) => record.items.any(
                (item) =>
                    _matches(item.name, preset.componentName) ||
                    _matches(item.name, preset.serviceType),
              ),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final byDate = b.serviceDate.compareTo(a.serviceDate);
            return byDate != 0 ? byDate : b.odometer.compareTo(a.odometer);
          });
    final lastService = relevantRecords.firstOrNull;
    final estimate = lastService == null
        ? null
        : MaintenanceEstimator.estimate(
            preset: preset,
            lastService: lastService,
          );

    final candidates = <_Candidate>[];
    if (estimate != null &&
        (estimate.dueDate != null || estimate.dueOdometer != null)) {
      candidates.add(
        _fromDueStatus(
          _calculateEstimateStatus(
            estimate: estimate,
            now: now,
            currentOdometer: currentOdometer,
          ),
        ),
      );
    }

    for (final schedule in schedules.where(
      (schedule) =>
          !schedule.isCompleted &&
          (_matches(schedule.serviceType, preset.componentName) ||
              _matches(schedule.serviceType, preset.serviceType) ||
              _matches(schedule.title, preset.componentName)),
    )) {
      candidates.add(
        _fromDueStatus(
          ServiceScheduleDueCalculator.calculate(
            schedule: schedule,
            now: now,
            currentOdometer: currentOdometer,
          ),
        ),
      );
    }

    if (candidates.isEmpty) {
      return MaintenanceHealthItem(
        preset: preset,
        status: MaintenanceHealthStatus.noData,
        description: 'Belum ada catatan atau jadwal perawatan',
      );
    }
    candidates.sort((a, b) => b.rank.compareTo(a.rank));
    final mostUrgent = candidates.first;
    final description = _description(
      candidate: mostUrgent,
      lastService: lastService,
      currentOdometer: currentOdometer,
    );
    return MaintenanceHealthItem(
      preset: preset,
      status: mostUrgent.status,
      description: description,
      estimate: estimate,
    );
  }

  static ServiceScheduleDueStatus _calculateEstimateStatus({
    required MaintenanceEstimate estimate,
    required DateTime now,
    required int currentOdometer,
  }) {
    final dueDate = estimate.dueDate ?? DateTime(now.year + 100);
    return ServiceScheduleDueCalculator.calculate(
      schedule: ServiceSchedule(
        id: 'estimate',
        title: 'Estimasi',
        serviceType: 'Estimasi',
        dueDate: dueDate,
        dueOdometer: estimate.dueOdometer,
        reminderAt: dueDate,
        reminderEnabled: false,
        localNotificationId: 0,
        status: ServiceScheduleStatus.pending,
      ),
      now: now,
      currentOdometer: currentOdometer,
    );
  }

  static _Candidate _fromDueStatus(ServiceScheduleDueStatus due) {
    final visual = due.visualState();
    final status = switch (visual) {
      ServiceScheduleVisualState.safe => MaintenanceHealthStatus.safe,
      ServiceScheduleVisualState.approaching =>
        MaintenanceHealthStatus.approaching,
      ServiceScheduleVisualState.due => MaintenanceHealthStatus.due,
      ServiceScheduleVisualState.overdue => MaintenanceHealthStatus.overdue,
    };
    return _Candidate(status: status, due: due);
  }

  static String _description({
    required _Candidate candidate,
    required ServiceRecord? lastService,
    required int currentOdometer,
  }) {
    final due = candidate.due;
    if (candidate.status == MaintenanceHealthStatus.overdue) {
      final km = due.odometer?.kilometersOverdue;
      final days = due.date.daysOverdue;
      if (km != null && km > 0) return 'Lewat ${_integer(km)} km';
      if (days != null && days > 0) return 'Lewat $days hari';
      return 'Ambang perawatan sudah tercapai';
    }
    if (candidate.status == MaintenanceHealthStatus.due) {
      return 'Jatuh tempo hari ini';
    }
    if (candidate.status == MaintenanceHealthStatus.approaching) {
      final km = due.odometer?.kilometersRemaining;
      final days = due.date.daysRemaining;
      if (km != null && km <= 500) return 'Sekitar ${_integer(km)} km lagi';
      if (days != null) return 'Sekitar $days hari lagi';
    }
    if (lastService != null) {
      final traveled = currentOdometer - lastService.odometer;
      if (traveled >= 0) {
        return 'Terakhir dirawat ${_integer(traveled)} km lalu';
      }
    }
    return due.labels.join(' · ');
  }

  static bool _matches(String value, String expected) {
    final normalizedValue = _normalize(value);
    final normalizedExpected = _normalize(expected);
    if (normalizedValue.isEmpty || normalizedExpected.isEmpty) return false;
    return normalizedValue == normalizedExpected ||
        normalizedValue.contains(normalizedExpected) ||
        normalizedExpected.contains(normalizedValue);
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  static String _integer(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
  }
}

class _Candidate {
  const _Candidate({required this.status, required this.due});

  final MaintenanceHealthStatus status;
  final ServiceScheduleDueStatus due;

  int get rank => switch (status) {
    MaintenanceHealthStatus.noData => 0,
    MaintenanceHealthStatus.safe => 1,
    MaintenanceHealthStatus.approaching => 2,
    MaintenanceHealthStatus.due => 3,
    MaintenanceHealthStatus.overdue => 4,
  };
}

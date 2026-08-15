import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

class MonthlyExpense {
  const MonthlyExpense({required this.month, required this.total});

  final DateTime month;
  final int total;
}

class DashboardSummary {
  const DashboardSummary({
    required this.activeVehicle,
    required this.latestService,
    required this.nearestPendingSchedule,
    required this.currentMonthExpense,
    required this.currentYearExpense,
    required this.monthlyExpenses,
  });

  final Vehicle? activeVehicle;
  final ServiceRecord? latestService;
  final ServiceSchedule? nearestPendingSchedule;
  final int currentMonthExpense;
  final int currentYearExpense;
  final List<MonthlyExpense> monthlyExpenses;
}

abstract final class DashboardAggregator {
  static DashboardSummary aggregate({
    required Vehicle? activeVehicle,
    required Iterable<ServiceRecord> serviceRecords,
    required Iterable<ServiceSchedule> serviceSchedules,
    required DateTime now,
  }) {
    final localNow = now.toLocal();
    final records = serviceRecords.toList(growable: false);
    final schedules = serviceSchedules.toList(growable: false);

    final latestService = _latestService(records);
    final nearestSchedule = _nearestPendingSchedule(schedules);
    final monthlyExpenses = List<MonthlyExpense>.unmodifiable(
      List.generate(6, (index) {
        final month = DateTime(localNow.year, localNow.month - 5 + index);
        final total = records
            .where((record) => _isSameMonth(record.serviceDate, month))
            .fold<int>(0, (sum, record) => sum + record.totalCost);
        return MonthlyExpense(month: month, total: total);
      }),
    );

    return DashboardSummary(
      activeVehicle: activeVehicle,
      latestService: latestService,
      nearestPendingSchedule: nearestSchedule,
      currentMonthExpense: records
          .where((record) => _isSameMonth(record.serviceDate, localNow))
          .fold<int>(0, (sum, record) => sum + record.totalCost),
      currentYearExpense: records
          .where((record) => record.serviceDate.toLocal().year == localNow.year)
          .fold<int>(0, (sum, record) => sum + record.totalCost),
      monthlyExpenses: monthlyExpenses,
    );
  }

  static ServiceRecord? _latestService(List<ServiceRecord> records) {
    ServiceRecord? latest;
    for (final record in records) {
      if (latest == null || record.serviceDate.isAfter(latest.serviceDate)) {
        latest = record;
      }
    }
    return latest;
  }

  static ServiceSchedule? _nearestPendingSchedule(
    List<ServiceSchedule> schedules,
  ) {
    final pending = schedules
        .where((schedule) => schedule.status == ServiceScheduleStatus.pending)
        .toList();
    if (pending.isEmpty) return null;

    pending.sort((left, right) => left.dueDate.compareTo(right.dueDate));
    return pending.first;
  }

  static bool _isSameMonth(DateTime value, DateTime month) {
    final localValue = value.toLocal();
    return localValue.year == month.year && localValue.month == month.month;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/features/dashboard/domain/models/dashboard_summary.dart';
import 'package:mentorride/features/service_records/domain/models/service_action.dart';
import 'package:mentorride/features/service_records/domain/models/service_item.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

void main() {
  group('DashboardAggregator.aggregate', () {
    test('merangkum kendaraan, servis, jadwal, dan pengeluaran', () {
      const vehicle = Vehicle(
        id: 'vehicle-1',
        name: 'Motor Harian',
        brand: 'Honda',
        model: 'Vario',
        year: 2022,
        plateNumber: 'B 1234 XYZ',
        currentOdometer: 15000,
      );
      final latest = _record('august-latest', DateTime(2026, 8, 20), 50000);
      final records = [
        _record('previous-year', DateTime(2025, 12, 31), 999000),
        _record('january', DateTime(2026, 1, 5), 100000),
        _record('march', DateTime(2026, 3, 5), 200000),
        _record('july', DateTime(2026, 7, 5), 300000),
        _record('august', DateTime(2026, 8, 1), 400000),
        latest,
      ];
      final nearestPending = _schedule(
        'near',
        DateTime(2026, 8, 25),
        ServiceScheduleStatus.pending,
      );
      final schedules = [
        _schedule(
          'completed',
          DateTime(2026, 8, 16),
          ServiceScheduleStatus.completed,
        ),
        _schedule('far', DateTime(2026, 9, 15), ServiceScheduleStatus.pending),
        nearestPending,
      ];

      final summary = DashboardAggregator.aggregate(
        activeVehicle: vehicle,
        serviceRecords: records,
        serviceSchedules: schedules,
        now: DateTime(2026, 8, 15),
      );

      expect(summary.activeVehicle, same(vehicle));
      expect(summary.latestService, same(latest));
      expect(summary.nearestPendingSchedule, same(nearestPending));
      expect(summary.currentMonthExpense, 450000);
      expect(summary.currentYearExpense, 1050000);
      expect(summary.monthlyExpenses.map((expense) => expense.month.month), [
        3,
        4,
        5,
        6,
        7,
        8,
      ]);
      expect(summary.monthlyExpenses.map((expense) => expense.total), [
        200000,
        0,
        0,
        0,
        300000,
        450000,
      ]);
    });

    test('menghasilkan nilai kosong yang konsisten tanpa data', () {
      final summary = DashboardAggregator.aggregate(
        activeVehicle: null,
        serviceRecords: const [],
        serviceSchedules: const [],
        now: DateTime(2026, 8, 15),
      );

      expect(summary.activeVehicle, isNull);
      expect(summary.latestService, isNull);
      expect(summary.nearestPendingSchedule, isNull);
      expect(summary.currentMonthExpense, 0);
      expect(summary.currentYearExpense, 0);
      expect(summary.monthlyExpenses, hasLength(6));
      expect(
        summary.monthlyExpenses.every((expense) => expense.total == 0),
        isTrue,
      );
    });
  });
}

ServiceRecord _record(String id, DateTime date, int cost) {
  return ServiceRecord(
    id: id,
    serviceDate: date,
    odometer: 10000,
    workshop: 'Bengkel Mentor',
    items: [
      ServiceItem(name: 'Servis', action: ServiceAction.servis, cost: cost),
    ],
    notes: '',
  );
}

ServiceSchedule _schedule(
  String id,
  DateTime dueDate,
  ServiceScheduleStatus status,
) {
  return ServiceSchedule(
    id: id,
    title: 'Jadwal $id',
    serviceType: 'Servis berkala',
    dueDate: dueDate,
    dueOdometer: null,
    reminderAt: dueDate.subtract(const Duration(days: 1)),
    reminderEnabled: false,
    localNotificationId: 1,
    status: status,
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/domain/services/service_schedule_due_calculator.dart';

void main() {
  group('dimensi tanggal', () {
    test('mengabaikan jam ketika menghitung hari yang tersisa', () {
      final result = _calculate(
        dueDate: DateTime(2026, 8, 20, 0, 1),
        now: DateTime(2026, 8, 15, 23, 59),
      );

      expect(result.date.state, ServiceDueDateState.upcoming);
      expect(result.date.daysUntilDue, 5);
      expect(result.date.daysRemaining, 5);
      expect(result.date.daysOverdue, isNull);
      expect(result.date.label, '5 hari lagi');
    });

    test('tanggal sebelum hari ini dinyatakan terlambat', () {
      final result = _calculate(
        dueDate: DateTime(2026, 8, 13, 23, 59),
        now: DateTime(2026, 8, 15, 0, 1),
      );

      expect(result.date.state, ServiceDueDateState.overdue);
      expect(result.date.daysUntilDue, -2);
      expect(result.date.daysOverdue, 2);
      expect(result.date.daysRemaining, isNull);
      expect(result.date.label, 'Terlambat 2 hari');
    });

    test('tanggal yang sama tetap jatuh tempo hari ini meski jam berbeda', () {
      final result = _calculate(
        dueDate: DateTime(2026, 8, 15),
        now: DateTime(2026, 8, 15, 23, 59, 59),
      );

      expect(result.date.state, ServiceDueDateState.today);
      expect(result.date.daysUntilDue, 0);
      expect(result.date.daysRemaining, isNull);
      expect(result.date.daysOverdue, isNull);
      expect(result.date.isDueToday, isTrue);
      expect(result.date.label, 'Jatuh tempo hari ini');
    });

    test('menghitung lintas bulan dan tahun berdasarkan hari kalender', () {
      final result = _calculate(
        dueDate: DateTime(2027, 1, 2, 1),
        now: DateTime(2026, 12, 31, 22),
      );

      expect(result.date.daysRemaining, 2);
      expect(result.date.label, '2 hari lagi');
    });
  });

  group('dimensi odometer', () {
    test('dueOdometer null menghasilkan status berbasis tanggal saja', () {
      final result = _calculate(
        dueDate: DateTime(2026, 8, 20),
        now: DateTime(2026, 8, 15),
      );

      expect(result.odometer, isNull);
      expect(result.labels, ['5 hari lagi']);
    });

    test('menghitung kilometer yang masih tersisa', () {
      final result = _calculate(
        dueDate: DateTime(2026, 8, 20),
        dueOdometer: 12500,
        currentOdometer: 10000,
        now: DateTime(2026, 8, 15),
      );

      expect(result.odometer?.state, ServiceDueOdometerState.upcoming);
      expect(result.odometer?.kilometersUntilDue, 2500);
      expect(result.odometer?.kilometersRemaining, 2500);
      expect(result.odometer?.kilometersOverdue, isNull);
      expect(result.odometer?.label, '2.500 km lagi');
    });

    test('odometer yang sama dengan ambang sudah dinyatakan overdue', () {
      final result = _calculate(
        dueDate: DateTime(2026, 8, 20),
        dueOdometer: 12500,
        currentOdometer: 12500,
        now: DateTime(2026, 8, 15),
      );

      expect(result.odometer?.state, ServiceDueOdometerState.overdue);
      expect(result.odometer?.isOverdue, isTrue);
      expect(result.odometer?.kilometersUntilDue, 0);
      expect(result.odometer?.kilometersOverdue, 0);
      expect(result.odometer?.kilometersRemaining, isNull);
      expect(result.odometer?.label, 'Terlambat berdasarkan kilometer');
    });

    test('menghitung kilometer yang telah melewati ambang', () {
      final result = _calculate(
        dueDate: DateTime(2026, 8, 20),
        dueOdometer: 12500,
        currentOdometer: 13250,
        now: DateTime(2026, 8, 15),
      );

      expect(result.odometer?.state, ServiceDueOdometerState.overdue);
      expect(result.odometer?.kilometersUntilDue, -750);
      expect(result.odometer?.kilometersOverdue, 750);
      expect(result.odometer?.kilometersRemaining, isNull);
      expect(result.odometer?.label, 'Terlambat 750 km');
    });
  });

  group('hasil gabungan', () {
    test('mempertahankan tanggal overdue dan odometer upcoming sekaligus', () {
      final result = _calculate(
        dueDate: DateTime(2026, 8, 10),
        dueOdometer: 15000,
        currentOdometer: 14000,
        now: DateTime(2026, 8, 15),
      );

      expect(result.date.state, ServiceDueDateState.overdue);
      expect(result.odometer?.state, ServiceDueOdometerState.upcoming);
      expect(result.isOverdue, isTrue);
      expect(result.labels, ['Terlambat 5 hari', '1.000 km lagi']);
    });

    test('mempertahankan tanggal upcoming dan odometer overdue sekaligus', () {
      final result = _calculate(
        dueDate: DateTime(2026, 8, 20),
        dueOdometer: 15000,
        currentOdometer: 15500,
        now: DateTime(2026, 8, 15),
      );

      expect(result.date.state, ServiceDueDateState.upcoming);
      expect(result.odometer?.state, ServiceDueOdometerState.overdue);
      expect(result.isOverdue, isTrue);
      expect(result.labels, ['5 hari lagi', 'Terlambat 500 km']);
    });

    test('tidak overdue bila kedua ambang belum tercapai', () {
      final result = _calculate(
        dueDate: DateTime(2026, 8, 20),
        dueOdometer: 15000,
        currentOdometer: 14000,
        now: DateTime(2026, 8, 15),
      );

      expect(result.isOverdue, isFalse);
      expect(result.isDueToday, isFalse);
    });

    test('model terserialisasi lama tetap dapat dihitung tanpa migrasi', () {
      final schedule = ServiceSchedule.fromMap({
        'id': 'schedule-1',
        'title': 'Servis berkala',
        'serviceType': 'Ganti oli',
        'dueDate': '2026-08-15T23:59:00.000',
        'dueOdometer': null,
        'reminderAt': '2026-08-14T08:00:00.000',
        'reminderEnabled': false,
        'localNotificationId': 1,
        'status': 'pending',
        'createdAt': null,
        'updatedAt': null,
      });

      final result = ServiceScheduleDueCalculator.calculate(
        schedule: schedule,
        now: DateTime(2026, 8, 15),
        currentOdometer: 10000,
      );

      expect(result.date.state, ServiceDueDateState.today);
      expect(result.odometer, isNull);
      expect(schedule.createdAt, isNull);
      expect(schedule.updatedAt, isNull);
    });
  });
}

ServiceScheduleDueStatus _calculate({
  required DateTime dueDate,
  required DateTime now,
  int? dueOdometer,
  int currentOdometer = 10000,
}) {
  final schedule = ServiceSchedule(
    id: 'schedule-1',
    title: 'Servis berkala',
    serviceType: 'Ganti oli',
    dueDate: dueDate,
    dueOdometer: dueOdometer,
    reminderAt: dueDate.subtract(const Duration(days: 1)),
    reminderEnabled: false,
    localNotificationId: 1,
    status: ServiceScheduleStatus.pending,
  );

  return ServiceScheduleDueCalculator.calculate(
    schedule: schedule,
    now: now,
    currentOdometer: currentOdometer,
  );
}

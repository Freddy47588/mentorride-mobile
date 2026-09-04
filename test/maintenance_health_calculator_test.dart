import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/core/maintenance/maintenance_preset.dart';
import 'package:mentorride/features/maintenance_health/domain/models/maintenance_health.dart';
import 'package:mentorride/features/maintenance_health/domain/services/maintenance_estimator.dart';
import 'package:mentorride/features/maintenance_health/domain/services/maintenance_health_calculator.dart';
import 'package:mentorride/features/service_records/domain/models/service_action.dart';
import 'package:mentorride/features/service_records/domain/models/service_item.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';

void main() {
  const kilometerPreset = MaintenancePreset(
    componentName: 'Oli mesin',
    serviceType: 'Ganti oli mesin',
    actionWireValue: 'ganti',
    intervalKilometers: 2000,
  );
  const datePreset = MaintenancePreset(
    componentName: 'CVT',
    serviceType: 'Servis CVT',
    actionWireValue: 'servis',
    intervalMonths: 1,
  );

  test('health summary Aman', () {
    final item = _calculate(
      preset: kilometerPreset,
      record: _record(name: 'Oli mesin', odometer: 10000),
      currentOdometer: 11000,
    );
    expect(item.status, MaintenanceHealthStatus.safe);
  });

  test('health summary Mendekati', () {
    final item = _calculate(
      preset: kilometerPreset,
      record: _record(name: 'Oli mesin', odometer: 10000),
      currentOdometer: 11500,
    );
    expect(item.status, MaintenanceHealthStatus.approaching);
    expect(item.description, 'Sekitar 500 km lagi');
  });

  test('health summary Jatuh tempo', () {
    final item = _calculate(
      preset: datePreset,
      record: _record(name: 'CVT', date: DateTime(2026, 8, 4)),
      currentOdometer: 10000,
      now: DateTime(2026, 9, 4, 23),
    );
    expect(item.status, MaintenanceHealthStatus.due);
  });

  test('health summary Terlambat', () {
    final item = _calculate(
      preset: kilometerPreset,
      record: _record(name: 'Oli mesin', odometer: 10000),
      currentOdometer: 12100,
    );
    expect(item.status, MaintenanceHealthStatus.overdue);
    expect(item.description, 'Lewat 100 km');
  });

  test('health summary Belum ada data', () {
    final summary = MaintenanceHealthCalculator.calculate(
      records: const [],
      schedules: const [],
      currentOdometer: 10000,
      now: DateTime(2026, 9, 4),
      presets: const [kilometerPreset],
    );
    expect(summary.items.single.status, MaintenanceHealthStatus.noData);
    expect(summary.percentage, isNull);
  });

  test('maintenance estimation by kilometer and date', () {
    final estimate = MaintenanceEstimator.estimate(
      preset: const MaintenancePreset(
        componentName: 'Oli mesin',
        serviceType: 'Ganti oli mesin',
        actionWireValue: 'ganti',
        intervalKilometers: 2000,
        intervalMonths: 3,
      ),
      lastService: _record(
        name: 'Oli mesin',
        odometer: 12000,
        date: DateTime(2026, 7, 1),
      ),
    );
    expect(estimate.dueOdometer, 14000);
    expect(estimate.dueDate, DateTime(2026, 10, 1));
  });
}

MaintenanceHealthItem _calculate({
  required MaintenancePreset preset,
  required ServiceRecord record,
  required int currentOdometer,
  DateTime? now,
}) {
  return MaintenanceHealthCalculator.calculate(
    records: [record],
    schedules: const [],
    currentOdometer: currentOdometer,
    now: now ?? DateTime(2026, 9, 4),
    presets: [preset],
  ).items.single;
}

ServiceRecord _record({
  required String name,
  int odometer = 10000,
  DateTime? date,
}) {
  return ServiceRecord(
    id: 'record-1',
    serviceDate: date ?? DateTime(2026, 8, 1),
    odometer: odometer,
    workshop: '',
    items: [ServiceItem(name: name, action: ServiceAction.ganti, cost: 0)],
    notes: '',
  );
}

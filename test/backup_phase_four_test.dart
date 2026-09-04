import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/core/errors/app_exception.dart';
import 'package:mentorride/features/backup/domain/models/mentorride_backup.dart';
import 'package:mentorride/features/backup/domain/services/backup_id_remapper.dart';
import 'package:mentorride/features/backup/domain/services/backup_serializer.dart';
import 'package:mentorride/features/odometer/domain/models/odometer_log.dart';
import 'package:mentorride/features/service_records/domain/models/service_action.dart';
import 'package:mentorride/features/service_records/domain/models/service_item.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

void main() {
  test('backup serialization dan schema validator', () {
    final encoded = BackupSerializer.serialize(_backup());
    final decoded = BackupSerializer.deserialize(encoded);
    expect(decoded.vehicles, hasLength(1));
    expect(decoded.vehicles.single.vehicle.isArchived, isTrue);
    expect(decoded.vehicles.single.serviceRecords.single.totalCost, 125000);
    expect(
      decoded.vehicles.single.odometerLogs.single.source,
      OdometerLogSource.serviceRecord,
    );
  });

  test('corrupted backup ditolak sebelum restore', () {
    expect(
      () => BackupSerializer.deserialize('{rusak'),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          contains('rusak'),
        ),
      ),
    );
  });

  test('unsupported backup version ditolak', () {
    final map = jsonDecode(BackupSerializer.serialize(_backup())) as Map;
    map['version'] = 99;
    expect(
      () => BackupSerializer.deserialize(jsonEncode(map)),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          contains('belum didukung'),
        ),
      ),
    );
  });

  test('restore ID remapping membuat ID baru dan stabil per kendaraan', () {
    var counter = 0;
    final mapping = BackupIdRemapper.vehicleIds([
      'old-a',
      'old-b',
    ], () => 'new-${++counter}');
    expect(mapping, {'old-a': 'new-1', 'old-b': 'new-2'});
    expect(mapping.values, isNot(contains('old-a')));
  });
}

MentorRideBackup _backup() {
  final serviceDate = DateTime.utc(2026, 8, 1);
  return MentorRideBackup(
    exportedAt: DateTime.utc(2026, 9, 4),
    vehicles: [
      BackupVehicleData(
        vehicle: const Vehicle(
          id: 'vehicle-1',
          name: 'Motor harian',
          brand: 'Honda',
          model: 'Vario',
          year: 2024,
          plateNumber: 'B 1234 XYZ',
          currentOdometer: 12000,
          isArchived: true,
        ),
        serviceRecords: [
          ServiceRecord(
            id: 'record-1',
            serviceDate: serviceDate,
            odometer: 12000,
            workshop: 'Bengkel',
            items: const [
              ServiceItem(
                name: 'Oli mesin',
                action: ServiceAction.ganti,
                cost: 125000,
              ),
            ],
            notes: '',
          ),
        ],
        serviceSchedules: [
          ServiceSchedule(
            id: 'schedule-1',
            title: 'Ganti oli',
            serviceType: 'Oli mesin',
            dueDate: DateTime.utc(2026, 10, 1),
            dueOdometer: 14000,
            reminderAt: DateTime.utc(2026, 9, 30),
            reminderEnabled: false,
            localNotificationId: 10,
            status: ServiceScheduleStatus.pending,
          ),
        ],
        odometerLogs: [
          OdometerLog(
            id: 'log-1',
            odometer: 12000,
            recordedAt: serviceDate,
            source: OdometerLogSource.serviceRecord,
          ),
        ],
      ),
    ],
  );
}

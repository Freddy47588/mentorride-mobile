import 'package:mentorride/features/odometer/domain/models/odometer_log.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

class BackupVehicleData {
  const BackupVehicleData({
    required this.vehicle,
    required this.serviceRecords,
    required this.serviceSchedules,
    required this.odometerLogs,
  });

  final Vehicle vehicle;
  final List<ServiceRecord> serviceRecords;
  final List<ServiceSchedule> serviceSchedules;
  final List<OdometerLog> odometerLogs;
}

class MentorRideBackup {
  const MentorRideBackup({required this.exportedAt, required this.vehicles});

  static const format = 'mentorride-backup';
  static const version = 1;

  final DateTime exportedAt;
  final List<BackupVehicleData> vehicles;
}

class BackupRestoreResult {
  const BackupRestoreResult({
    required this.vehicleIdMapping,
    required this.vehicleCount,
    required this.recordCount,
    required this.scheduleCount,
    required this.odometerLogCount,
    required this.reminders,
  });

  final Map<String, String> vehicleIdMapping;
  final int vehicleCount;
  final int recordCount;
  final int scheduleCount;
  final int odometerLogCount;
  final List<RestoredReminder> reminders;
}

class RestoredReminder {
  const RestoredReminder({
    required this.notificationId,
    required this.scheduleId,
    required this.title,
    required this.serviceType,
    required this.reminderAt,
  });

  final int notificationId;
  final String scheduleId;
  final String title;
  final String serviceType;
  final DateTime reminderAt;
}

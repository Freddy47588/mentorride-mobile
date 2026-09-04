import 'package:mentorride/features/backup/domain/models/mentorride_backup.dart';

abstract final class BackupMapper {
  static Map<String, Object?> toMap(MentorRideBackup backup) {
    return {
      'format': MentorRideBackup.format,
      'version': MentorRideBackup.version,
      'exportedAt': backup.exportedAt.toUtc().toIso8601String(),
      'vehicles': backup.vehicles.map((data) {
        final vehicle = data.vehicle;
        return <String, Object?>{
          'id': vehicle.id,
          'name': vehicle.name,
          'brand': vehicle.brand,
          'model': vehicle.model,
          'year': vehicle.year,
          'plateNumber': vehicle.plateNumber,
          'currentOdometer': vehicle.currentOdometer,
          'isArchived': vehicle.isArchived,
          'createdAt': _date(vehicle.createdAt),
          'updatedAt': _date(vehicle.updatedAt),
          'serviceRecords': data.serviceRecords.map((record) {
            return <String, Object?>{
              'id': record.id,
              'serviceDate': _date(record.serviceDate),
              'odometer': record.odometer,
              'workshop': record.workshop,
              'items': record.items.map((item) => item.toMap()).toList(),
              'notes': record.notes,
              'createdAt': _date(record.createdAt),
              'updatedAt': _date(record.updatedAt),
            };
          }).toList(),
          'serviceSchedules': data.serviceSchedules.map((schedule) {
            return <String, Object?>{
              'id': schedule.id,
              'title': schedule.title,
              'serviceType': schedule.serviceType,
              'dueDate': _date(schedule.dueDate),
              'dueOdometer': schedule.dueOdometer,
              'reminderAt': _date(schedule.reminderAt),
              'reminderEnabled': schedule.reminderEnabled,
              'localNotificationId': schedule.localNotificationId,
              'status': schedule.status.storageValue,
              'createdAt': _date(schedule.createdAt),
              'updatedAt': _date(schedule.updatedAt),
            };
          }).toList(),
          'odometerLogs': data.odometerLogs.map((log) {
            return <String, Object?>{
              'id': log.id,
              'odometer': log.odometer,
              'recordedAt': _date(log.recordedAt),
              'source': log.source.storageValue,
            };
          }).toList(),
        };
      }).toList(),
    };
  }

  static String? _date(DateTime? value) => value?.toUtc().toIso8601String();
}

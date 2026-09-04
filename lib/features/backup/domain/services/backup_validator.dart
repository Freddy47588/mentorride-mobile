import 'package:mentorride/core/errors/app_exception.dart';
import 'package:mentorride/features/backup/domain/models/mentorride_backup.dart';
import 'package:mentorride/features/odometer/domain/models/odometer_log.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

abstract final class BackupValidator {
  static MentorRideBackup validate(Map<String, Object?> map) {
    if (map['format'] != MentorRideBackup.format) {
      throw const AppException('File bukan cadangan MentorRide yang valid.');
    }
    final version = map['version'];
    if (version is! int || version != MentorRideBackup.version) {
      throw const AppException('Versi cadangan belum didukung.');
    }
    final exportedAt = _requiredDate(map, 'exportedAt', 'cadangan');
    final vehiclesRaw = _requiredList(map, 'vehicles', 'cadangan');
    final vehicles = <BackupVehicleData>[];
    for (var index = 0; index < vehiclesRaw.length; index++) {
      vehicles.add(_vehicle(_object(vehiclesRaw[index], 'kendaraan'), index));
    }
    _ensureUniqueIds(vehicles.map((data) => data.vehicle.id), 'kendaraan');
    return MentorRideBackup(exportedAt: exportedAt, vehicles: vehicles);
  }

  static BackupVehicleData _vehicle(Map<String, Object?> map, int index) {
    final context = 'kendaraan ke-${index + 1}';
    final id = _requiredString(map, 'id', context);
    final year = _nonNegativeInt(map, 'year', context);
    final maximumYear = DateTime.now().year + 1;
    if (year < 1900 || year > maximumYear) {
      throw AppException(
        'Tahun pada $context harus antara 1900 dan $maximumYear.',
      );
    }
    final vehicle = Vehicle(
      id: id,
      name: _requiredString(map, 'name', context),
      brand: _requiredString(map, 'brand', context),
      model: _requiredString(map, 'model', context),
      year: year,
      plateNumber: _requiredString(map, 'plateNumber', context),
      currentOdometer: _nonNegativeInt(map, 'currentOdometer', context),
      isArchived: _optionalBool(map, 'isArchived') ?? false,
      createdAt: _optionalDate(map, 'createdAt', context),
      updatedAt: _optionalDate(map, 'updatedAt', context),
    );
    final records = _requiredList(map, 'serviceRecords', context)
        .map((value) => _record(_object(value, 'riwayat servis'), context))
        .toList(growable: false);
    final schedules = _requiredList(map, 'serviceSchedules', context)
        .map((value) => _schedule(_object(value, 'jadwal servis'), context))
        .toList(growable: false);
    final logs = _requiredList(map, 'odometerLogs', context)
        .map((value) => _log(_object(value, 'riwayat kilometer'), context))
        .toList(growable: false);
    _ensureUniqueIds(records.map((record) => record.id), 'riwayat servis');
    _ensureUniqueIds(schedules.map((schedule) => schedule.id), 'jadwal servis');
    _ensureUniqueIds(logs.map((log) => log.id), 'riwayat kilometer');
    var highestObservedOdometer = 0;
    for (final record in records) {
      if (record.odometer > highestObservedOdometer) {
        highestObservedOdometer = record.odometer;
      }
    }
    final chronologicalLogs = logs.toList()
      ..sort((a, b) => a.recordedAt!.compareTo(b.recordedAt!));
    var previousLogOdometer = -1;
    for (final log in chronologicalLogs) {
      if (log.odometer <= previousLogOdometer) {
        throw const AppException(
          'Riwayat kilometer dalam cadangan harus selalu meningkat.',
        );
      }
      previousLogOdometer = log.odometer;
      if (log.odometer > highestObservedOdometer) {
        highestObservedOdometer = log.odometer;
      }
    }
    if (highestObservedOdometer > vehicle.currentOdometer) {
      throw AppException(
        'Kilometer saat ini pada $context lebih kecil dari riwayatnya.',
      );
    }
    return BackupVehicleData(
      vehicle: vehicle,
      serviceRecords: records,
      serviceSchedules: schedules,
      odometerLogs: logs,
    );
  }

  static ServiceRecord _record(Map<String, Object?> map, String context) {
    final items = _requiredList(map, 'items', context)
        .map((value) {
          final item = _object(value, 'item servis');
          final cost = _nonNegativeInt(item, 'cost', 'item servis');
          final name = _requiredString(item, 'name', 'item servis');
          final action = _requiredString(item, 'action', 'item servis');
          if (!const {'ganti', 'servis', 'periksa'}.contains(action)) {
            throw const AppException('Jenis tindakan servis tidak valid.');
          }
          return {'name': name, 'action': action, 'cost': cost};
        })
        .toList(growable: false);
    if (items.isEmpty) {
      throw const AppException('Riwayat servis tidak memiliki item.');
    }
    return ServiceRecord.fromMap({
      'id': _requiredString(map, 'id', context),
      'serviceDate': _requiredDate(map, 'serviceDate', context),
      'odometer': _nonNegativeInt(map, 'odometer', context),
      'workshop': _requiredString(map, 'workshop', context, allowEmpty: true),
      'items': items,
      'notes': _requiredString(map, 'notes', context, allowEmpty: true),
      'createdAt': _optionalDate(map, 'createdAt', context),
      'updatedAt': _optionalDate(map, 'updatedAt', context),
    });
  }

  static ServiceSchedule _schedule(Map<String, Object?> map, String context) {
    final dueOdometer = map['dueOdometer'];
    if (dueOdometer != null && (dueOdometer is! int || dueOdometer < 0)) {
      throw const AppException('Kilometer jadwal tidak valid.');
    }
    final status = _requiredString(map, 'status', context);
    if (!const {'pending', 'completed'}.contains(status)) {
      throw const AppException('Status jadwal tidak valid.');
    }
    return ServiceSchedule.fromMap({
      'id': _requiredString(map, 'id', context),
      'title': _requiredString(map, 'title', context),
      'serviceType': _requiredString(map, 'serviceType', context),
      'dueDate': _requiredDate(map, 'dueDate', context),
      'dueOdometer': dueOdometer,
      'reminderAt': _requiredDate(map, 'reminderAt', context),
      'reminderEnabled': _requiredBool(map, 'reminderEnabled', context),
      'localNotificationId': _nonNegativeInt(
        map,
        'localNotificationId',
        context,
      ),
      'status': status,
      'createdAt': _optionalDate(map, 'createdAt', context),
      'updatedAt': _optionalDate(map, 'updatedAt', context),
    });
  }

  static OdometerLog _log(Map<String, Object?> map, String context) {
    final source = _requiredString(map, 'source', context);
    if (!const {'manual_update', 'service_record'}.contains(source)) {
      throw const AppException('Sumber riwayat kilometer tidak valid.');
    }
    return OdometerLog.fromMap({
      'id': _requiredString(map, 'id', context),
      'odometer': _nonNegativeInt(map, 'odometer', context),
      'recordedAt': _requiredDate(map, 'recordedAt', context),
      'source': source,
    });
  }

  static Map<String, Object?> _object(Object? value, String context) {
    if (value is! Map) throw AppException('Struktur $context tidak valid.');
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  static List<Object?> _requiredList(
    Map<String, Object?> map,
    String field,
    String context,
  ) {
    final value = map[field];
    if (value is! List) {
      throw AppException('Field $field pada $context wajib berupa daftar.');
    }
    return value;
  }

  static String _requiredString(
    Map<String, Object?> map,
    String field,
    String context, {
    bool allowEmpty = false,
  }) {
    final value = map[field];
    if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
      throw AppException('Field $field pada $context tidak valid.');
    }
    return value;
  }

  static int _nonNegativeInt(
    Map<String, Object?> map,
    String field,
    String context,
  ) {
    final value = map[field];
    if (value is! int || value < 0) {
      throw AppException(
        'Field $field pada $context harus bilangan bulat tidak negatif.',
      );
    }
    return value;
  }

  static bool _requiredBool(
    Map<String, Object?> map,
    String field,
    String context,
  ) {
    final value = map[field];
    if (value is! bool) {
      throw AppException('Field $field pada $context tidak valid.');
    }
    return value;
  }

  static bool? _optionalBool(Map<String, Object?> map, String field) {
    final value = map[field];
    if (value == null) return null;
    if (value is! bool) throw AppException('Field $field tidak valid.');
    return value;
  }

  static DateTime _requiredDate(
    Map<String, Object?> map,
    String field,
    String context,
  ) {
    final result = _optionalDate(map, field, context);
    if (result == null) {
      throw AppException('Field $field pada $context tidak valid.');
    }
    return result;
  }

  static DateTime? _optionalDate(
    Map<String, Object?> map,
    String field,
    String context,
  ) {
    final value = map[field];
    if (value == null) return null;
    if (value is! String) {
      throw AppException('Field $field pada $context tidak valid.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw AppException('Field $field pada $context tidak valid.');
    }
    return parsed;
  }

  static void _ensureUniqueIds(Iterable<String> ids, String context) {
    final seen = <String>{};
    for (final id in ids) {
      if (!seen.add(id)) {
        throw AppException('ID $context dalam cadangan harus unik.');
      }
    }
  }
}

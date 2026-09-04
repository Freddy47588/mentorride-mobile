import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentorride/core/errors/app_exception.dart';
import 'package:mentorride/core/notifications/notification_id.dart';
import 'package:mentorride/features/backup/domain/models/mentorride_backup.dart';
import 'package:mentorride/features/backup/domain/repositories/backup_repository.dart';
import 'package:mentorride/features/backup/domain/services/backup_id_remapper.dart';
import 'package:mentorride/features/odometer/domain/models/odometer_log.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:uuid/uuid.dart';

class FirestoreBackupRepository implements BackupRepository {
  FirestoreBackupRepository(this._firestore, [this._uuid = const Uuid()]);

  static const _pageSize = 400;
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> _vehicles(String uid) {
    return _firestore.collection('users').doc(uid).collection('vehicles');
  }

  @override
  Future<MentorRideBackup> createBackup(String uid) async {
    final vehicleDocuments = await _allDocuments(_vehicles(uid));
    final vehicles = <BackupVehicleData>[];
    for (final document in vehicleDocuments) {
      final data = document.data();
      final vehicle = Vehicle.fromMap({
        ...data,
        'id': document.id,
        'createdAt': _date(data['createdAt']),
        'updatedAt': _date(data['updatedAt']),
      });
      final recordsRaw = await _allDocuments(
        document.reference.collection('service_records'),
      );
      final schedulesRaw = await _allDocuments(
        document.reference.collection('service_schedules'),
      );
      final logsRaw = await _allDocuments(
        document.reference.collection('odometer_logs'),
      );
      vehicles.add(
        BackupVehicleData(
          vehicle: vehicle,
          serviceRecords: recordsRaw
              .map((record) {
                final value = record.data();
                return ServiceRecord.fromMap({
                  ...value,
                  'id': record.id,
                  'serviceDate': _date(value['serviceDate']),
                  'createdAt': _date(value['createdAt']),
                  'updatedAt': _date(value['updatedAt']),
                });
              })
              .toList(growable: false),
          serviceSchedules: schedulesRaw
              .map((schedule) {
                final value = schedule.data();
                return ServiceSchedule.fromMap({
                  ...value,
                  'id': schedule.id,
                  'dueDate': _date(value['dueDate']),
                  'reminderAt': _date(value['reminderAt']),
                  'createdAt': _date(value['createdAt']),
                  'updatedAt': _date(value['updatedAt']),
                });
              })
              .toList(growable: false),
          odometerLogs: logsRaw
              .map((log) {
                final value = log.data();
                return OdometerLog.fromMap({
                  ...value,
                  'id': log.id,
                  'recordedAt': _date(value['recordedAt']),
                });
              })
              .toList(growable: false),
        ),
      );
    }
    return MentorRideBackup(exportedAt: DateTime.now(), vehicles: vehicles);
  }

  @override
  Future<BackupRestoreResult> restoreBackup({
    required String uid,
    required MentorRideBackup backup,
  }) async {
    final idMapping = BackupIdRemapper.vehicleIds(
      backup.vehicles.map((data) => data.vehicle.id),
      _uuid.v4,
    );
    final writes = <_Write>[];
    var recordCount = 0;
    var scheduleCount = 0;
    var logCount = 0;
    final reminders = <RestoredReminder>[];

    for (final data in backup.vehicles) {
      final newVehicleId = idMapping[data.vehicle.id]!;
      final vehicleReference = _vehicles(uid).doc(newVehicleId);
      final vehicle = data.vehicle;
      writes.add(
        _Write(vehicleReference, {
          'name': vehicle.name.trim(),
          'brand': vehicle.brand.trim(),
          'model': vehicle.model.trim(),
          'year': vehicle.year,
          'plateNumber': vehicle.plateNumber.trim().toUpperCase(),
          'currentOdometer': vehicle.currentOdometer,
          'isArchived': vehicle.isArchived,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );
      for (final record in data.serviceRecords) {
        recordCount++;
        writes.add(
          _Write(
            vehicleReference.collection('service_records').doc(_uuid.v4()),
            {
              'serviceDate': Timestamp.fromDate(record.serviceDate),
              'odometer': record.odometer,
              'workshop': record.workshop.trim(),
              'items': record.items.map((item) => item.toMap()).toList(),
              'totalCost': record.totalCost,
              'notes': record.notes.trim(),
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          ),
        );
      }
      for (final schedule in data.serviceSchedules) {
        scheduleCount++;
        final scheduleId = _uuid.v4();
        final notificationId = StableNotificationId.fromUuid(scheduleId);
        writes.add(
          _Write(
            vehicleReference.collection('service_schedules').doc(scheduleId),
            {
              'title': schedule.title.trim(),
              'serviceType': schedule.serviceType.trim(),
              'dueDate': Timestamp.fromDate(schedule.dueDate),
              'dueOdometer': schedule.dueOdometer,
              'reminderAt': Timestamp.fromDate(schedule.reminderAt),
              'reminderEnabled': schedule.reminderEnabled,
              'localNotificationId': notificationId,
              'status': schedule.status.storageValue,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          ),
        );
        if (!vehicle.isArchived &&
            schedule.reminderEnabled &&
            !schedule.isCompleted &&
            schedule.reminderAt.isAfter(DateTime.now())) {
          reminders.add(
            RestoredReminder(
              notificationId: notificationId,
              scheduleId: scheduleId,
              title: schedule.title,
              serviceType: schedule.serviceType,
              reminderAt: schedule.reminderAt,
            ),
          );
        }
      }
      for (final log in data.odometerLogs) {
        logCount++;
        writes.add(
          _Write(vehicleReference.collection('odometer_logs').doc(_uuid.v4()), {
            'odometer': log.odometer,
            'recordedAt': Timestamp.fromDate(log.recordedAt!),
            'source': log.source.storageValue,
          }),
        );
      }
    }

    var committedWriteCount = 0;
    try {
      for (var start = 0; start < writes.length; start += _pageSize) {
        final batch = _firestore.batch();
        final end = start + _pageSize < writes.length
            ? start + _pageSize
            : writes.length;
        for (final write in writes.sublist(start, end)) {
          batch.set(write.reference, write.data);
        }
        await batch.commit();
        committedWriteCount = end;
      }
    } on Object catch (error, stackTrace) {
      final rollbackSucceeded = await _rollbackWrites(
        writes.take(committedWriteCount),
      );
      if (!rollbackSucceeded) {
        throw const AppException(
          'Pemulihan terhenti dan sebagian data baru mungkin masih tersimpan. '
          'Periksa daftar kendaraan sebelum mencoba kembali.',
        );
      }
      Error.throwWithStackTrace(_restoreError(error), stackTrace);
    }
    return BackupRestoreResult(
      vehicleIdMapping: idMapping,
      vehicleCount: backup.vehicles.length,
      recordCount: recordCount,
      scheduleCount: scheduleCount,
      odometerLogCount: logCount,
      reminders: List.unmodifiable(reminders),
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _allDocuments(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final result = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
    while (true) {
      Query<Map<String, dynamic>> query = collection
          .orderBy(FieldPath.documentId)
          .limit(_pageSize);
      if (cursor != null) query = query.startAfterDocument(cursor);
      final page = await query.get(const GetOptions(source: Source.server));
      result.addAll(page.docs);
      if (page.docs.length < _pageSize) break;
      cursor = page.docs.last;
    }
    return result;
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  Future<bool> _rollbackWrites(Iterable<_Write> committedWrites) async {
    final references = committedWrites
        .map((write) => write.reference)
        .toList(growable: false)
        .reversed
        .toList(growable: false);
    try {
      for (var start = 0; start < references.length; start += _pageSize) {
        final batch = _firestore.batch();
        final end = start + _pageSize < references.length
            ? start + _pageSize
            : references.length;
        for (final reference in references.sublist(start, end)) {
          batch.delete(reference);
        }
        await batch.commit();
      }
      return true;
    } on Object {
      return false;
    }
  }

  AppException _restoreError(Object error) {
    if (error is AppException) return error;
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' => const AppException(
          'Anda tidak memiliki izin untuk memulihkan data.',
          code: 'permission-denied',
        ),
        'unavailable' || 'deadline-exceeded' => const AppException(
          'Pemulihan belum dapat diselesaikan. Periksa koneksi Anda.',
          code: 'unavailable',
        ),
        _ => AppException(
          'Pemulihan data belum dapat diselesaikan. Silakan coba lagi.',
          code: error.code,
        ),
      };
    }
    return const AppException(
      'Pemulihan data belum dapat diselesaikan. Silakan coba lagi.',
    );
  }
}

class _Write {
  const _Write(this.reference, this.data);

  final DocumentReference<Map<String, dynamic>> reference;
  final Map<String, Object?> data;
}

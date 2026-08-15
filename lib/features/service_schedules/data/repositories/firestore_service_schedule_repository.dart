import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentorride/core/errors/app_exception.dart';
import 'package:mentorride/core/notifications/notification_id.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/domain/repositories/service_schedule_repository.dart';
import 'package:uuid/uuid.dart';

class FirestoreServiceScheduleRepository implements ServiceScheduleRepository {
  FirestoreServiceScheduleRepository(
    this._firestore, [
    this._uuid = const Uuid(),
  ]);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  @override
  Stream<List<ServiceSchedule>> watchServiceSchedules({
    required String uid,
    required String vehicleId,
  }) {
    return _schedules(uid, vehicleId)
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(_scheduleFromSnapshot).toList(growable: false),
        )
        .handleError((Object error, StackTrace stackTrace) {
          Error.throwWithStackTrace(_mapError(error), stackTrace);
        });
  }

  @override
  Future<ServiceSchedule> createServiceSchedule({
    required String uid,
    required String vehicleId,
    required ServiceSchedule schedule,
  }) async {
    final scheduleId = _uuid.v4();
    final created = schedule.copyWith(
      id: scheduleId,
      localNotificationId: StableNotificationId.fromUuid(scheduleId),
    );

    try {
      await _schedules(uid, vehicleId).doc(scheduleId).set({
        ..._writableData(created),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return created;
    } on Object catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> updateServiceSchedule({
    required String uid,
    required String vehicleId,
    required ServiceSchedule schedule,
  }) async {
    if (schedule.id.isEmpty) {
      throw const AppException('Jadwal servis tidak valid.');
    }

    final stableNotificationId = StableNotificationId.fromUuid(schedule.id);
    final updated = schedule.copyWith(
      localNotificationId: stableNotificationId,
    );

    try {
      await _schedules(uid, vehicleId).doc(schedule.id).update({
        ..._writableData(updated),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Object catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> deleteServiceSchedule({
    required String uid,
    required String vehicleId,
    required String scheduleId,
  }) async {
    if (scheduleId.isEmpty) return;

    try {
      await _schedules(uid, vehicleId).doc(scheduleId).delete();
    } on Object catch (error) {
      throw _mapError(error);
    }
  }

  CollectionReference<Map<String, dynamic>> _schedules(
    String uid,
    String vehicleId,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('vehicles')
        .doc(vehicleId)
        .collection('service_schedules');
  }

  ServiceSchedule _scheduleFromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return ServiceSchedule.fromMap({
      ...data,
      'id': snapshot.id,
      'dueDate': _dateTimeFrom(data['dueDate']),
      'reminderAt': _dateTimeFrom(data['reminderAt']),
      'createdAt': _dateTimeFrom(data['createdAt']),
      'updatedAt': _dateTimeFrom(data['updatedAt']),
    });
  }

  Map<String, Object?> _writableData(ServiceSchedule schedule) {
    return {
      'title': schedule.title.trim(),
      'serviceType': schedule.serviceType.trim(),
      'dueDate': Timestamp.fromDate(schedule.dueDate),
      'dueOdometer': schedule.dueOdometer,
      'reminderAt': Timestamp.fromDate(schedule.reminderAt),
      'reminderEnabled': schedule.reminderEnabled,
      'localNotificationId': schedule.localNotificationId,
      'status': schedule.status.storageValue,
    };
  }

  DateTime? _dateTimeFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  AppException _mapError(Object error) {
    if (error is AppException) return error;
    if (error is FirebaseException) {
      final message = switch (error.code) {
        'permission-denied' =>
          'Anda tidak memiliki izin untuk mengakses jadwal servis.',
        'unavailable' || 'deadline-exceeded' =>
          'Jadwal servis belum dapat diakses. Periksa koneksi Anda.',
        'not-found' => 'Jadwal servis tidak ditemukan.',
        _ => 'Jadwal servis belum dapat diproses. Silakan coba lagi.',
      };
      return AppException(message, code: error.code);
    }
    return const AppException(
      'Terjadi kesalahan saat memproses jadwal servis.',
    );
  }
}

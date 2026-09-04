import 'package:mentorride/core/errors/app_exception.dart';
import 'package:mentorride/core/notifications/notification_id.dart';
import 'package:mentorride/core/notifications/reminder_scheduler.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/domain/repositories/service_schedule_repository.dart';

class ServiceScheduleCoordinator {
  const ServiceScheduleCoordinator(this._repository, this._reminderScheduler);

  final ServiceScheduleRepository _repository;
  final ReminderScheduler _reminderScheduler;

  Future<ServiceSchedule> create({
    required String uid,
    required String vehicleId,
    required ServiceSchedule schedule,
  }) async {
    await _ensurePermissionWhenNeeded(schedule);
    final created = await _repository.createServiceSchedule(
      uid: uid,
      vehicleId: vehicleId,
      schedule: schedule,
    );
    try {
      await _syncReminder(created);
      return created;
    } on Object catch (error, stackTrace) {
      await _rollbackCreate(uid: uid, vehicleId: vehicleId, schedule: created);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> update({
    required String uid,
    required String vehicleId,
    required ServiceSchedule schedule,
    ServiceSchedule? previousSchedule,
  }) async {
    final normalized = _withStableNotificationId(schedule);
    await _ensurePermissionWhenNeeded(normalized);

    final previousNotificationId = previousSchedule?.localNotificationId;
    if (previousNotificationId != null &&
        previousNotificationId != normalized.localNotificationId) {
      await _reminderScheduler.cancel(previousNotificationId);
    }

    try {
      await _repository.updateServiceSchedule(
        uid: uid,
        vehicleId: vehicleId,
        schedule: normalized,
      );
    } on Object catch (error, stackTrace) {
      if (previousSchedule != null) {
        await _restoreReminder(previousSchedule);
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    try {
      await _syncReminder(normalized);
    } on Object catch (error, stackTrace) {
      await _rollbackUpdatedSchedule(
        uid: uid,
        vehicleId: vehicleId,
        previousSchedule: previousSchedule,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> delete({
    required String uid,
    required String vehicleId,
    required ServiceSchedule schedule,
  }) async {
    await _reminderScheduler.cancel(schedule.localNotificationId);
    try {
      await _repository.deleteServiceSchedule(
        uid: uid,
        vehicleId: vehicleId,
        scheduleId: schedule.id,
      );
    } on Object catch (error, stackTrace) {
      await _restoreReminder(schedule);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<ServiceSchedule> complete({
    required String uid,
    required String vehicleId,
    required ServiceSchedule schedule,
  }) async {
    final completed = _withStableNotificationId(
      schedule,
    ).copyWith(status: ServiceScheduleStatus.completed, reminderEnabled: false);
    await _reminderScheduler.cancel(schedule.localNotificationId);
    try {
      await _repository.updateServiceSchedule(
        uid: uid,
        vehicleId: vehicleId,
        schedule: completed,
      );
    } on Object catch (error, stackTrace) {
      await _restoreReminder(schedule);
      Error.throwWithStackTrace(error, stackTrace);
    }
    return completed;
  }

  bool _needsReminder(ServiceSchedule schedule) {
    return schedule.reminderEnabled &&
        !schedule.isCompleted &&
        schedule.reminderAt.isAfter(DateTime.now());
  }

  Future<void> _ensurePermissionWhenNeeded(ServiceSchedule schedule) async {
    if (!_needsReminder(schedule)) return;

    var permission = await _reminderScheduler.permissionStatus();
    if (permission != NotificationPermissionStatus.granted) {
      permission = await _reminderScheduler.requestPermission();
    }
    if (permission == NotificationPermissionStatus.granted) return;

    throw AppException(
      permission == NotificationPermissionStatus.denied
          ? 'Izin notifikasi diperlukan untuk mengaktifkan pengingat.'
          : 'Layanan notifikasi belum tersedia pada perangkat ini.',
    );
  }

  Future<void> _syncReminder(ServiceSchedule schedule) async {
    if (!_needsReminder(schedule)) {
      await _reminderScheduler.cancel(schedule.localNotificationId);
      return;
    }

    await _reminderScheduler.schedule(
      id: schedule.localNotificationId,
      title: 'Pengingat servis: ${schedule.title}',
      body: '${schedule.serviceType} untuk kendaraan Anda segera dijadwalkan.',
      scheduledAt: schedule.reminderAt,
      payload: '/schedules/${schedule.id}',
    );
  }

  ServiceSchedule _withStableNotificationId(ServiceSchedule schedule) {
    if (schedule.id.isEmpty) return schedule;
    return schedule.copyWith(
      localNotificationId: StableNotificationId.fromUuid(schedule.id),
    );
  }

  Future<void> _rollbackCreate({
    required String uid,
    required String vehicleId,
    required ServiceSchedule schedule,
  }) async {
    try {
      await _reminderScheduler.cancel(schedule.localNotificationId);
    } on Object {
      // Pembersihan best-effort; kegagalan penjadwalan awal tetap dilaporkan.
    }
    try {
      await _repository.deleteServiceSchedule(
        uid: uid,
        vehicleId: vehicleId,
        scheduleId: schedule.id,
      );
    } on Object {
      // Pembersihan best-effort; kegagalan penjadwalan awal tetap dilaporkan.
    }
  }

  Future<void> _rollbackUpdatedSchedule({
    required String uid,
    required String vehicleId,
    required ServiceSchedule? previousSchedule,
  }) async {
    if (previousSchedule == null) return;
    try {
      await _repository.updateServiceSchedule(
        uid: uid,
        vehicleId: vehicleId,
        schedule: previousSchedule,
      );
    } on Object {
      // Kompensasi Firestore bersifat best-effort; error awal tetap dilaporkan.
    }
    await _restoreReminder(_withStableNotificationId(previousSchedule));
  }

  Future<void> _restoreReminder(ServiceSchedule schedule) async {
    try {
      await _syncReminder(schedule);
    } on Object {
      // Kompensasi notifikasi bersifat best-effort; error awal tetap dilaporkan.
    }
  }
}
